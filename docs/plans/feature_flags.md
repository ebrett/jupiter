I'll help you create a comprehensive feature flag system with an admin interface to control the NationBuilder sign-in feature. Here's a complete implementation:

## 1. Database Migration

```sql
-- Create feature_flags table
CREATE TABLE feature_flags (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    is_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    INDEX idx_name (name),
    INDEX idx_enabled (is_enabled)
);

-- Insert the NationBuilder feature flag
INSERT INTO feature_flags (name, description, is_enabled) 
VALUES ('nationbuilder_signin', 'Enable NationBuilder sign-in functionality', FALSE);
```

## 2. Feature Flag Model

```php
<?php
// app/Models/FeatureFlag.php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class FeatureFlag extends Model
{
    protected $fillable = [
        'name',
        'description',
        'is_enabled',
        'created_by',
        'updated_by'
    ];

    protected $casts = [
        'is_enabled' => 'boolean',
    ];

    protected static function boot()
    {
        parent::boot();
        
        // Clear cache when feature flags are updated
        static::saved(function ($featureFlag) {
            Cache::forget("feature_flag_{$featureFlag->name}");
            Cache::forget('all_feature_flags');
        });
        
        static::deleted(function ($featureFlag) {
            Cache::forget("feature_flag_{$featureFlag->name}");
            Cache::forget('all_feature_flags');
        });
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater()
    {
        return $this->belongsTo(User::class, 'updated_by');
    }
}
```

## 3. Feature Flag Service

```php
<?php
// app/Services/FeatureFlagService.php

namespace App\Services;

use App\Models\FeatureFlag;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class FeatureFlagService
{
    private const CACHE_TTL = 3600; // 1 hour

    /**
     * Check if a feature is enabled
     */
    public function isEnabled(string $featureName): bool
    {
        try {
            return Cache::remember(
                "feature_flag_{$featureName}",
                self::CACHE_TTL,
                function () use ($featureName) {
                    $flag = FeatureFlag::where('name', $featureName)->first();
                    return $flag ? $flag->is_enabled : false;
                }
            );
        } catch (\Exception $e) {
            Log::error("Feature flag check failed for {$featureName}: " . $e->getMessage());
            return false; // Fail closed - feature disabled by default
        }
    }

    /**
     * Enable a feature
     */
    public function enable(string $featureName, ?int $userId = null): bool
    {
        return $this->setFlag($featureName, true, $userId);
    }

    /**
     * Disable a feature
     */
    public function disable(string $featureName, ?int $userId = null): bool
    {
        return $this->setFlag($featureName, false, $userId);
    }

    /**
     * Toggle a feature
     */
    public function toggle(string $featureName, ?int $userId = null): bool
    {
        $currentState = $this->isEnabled($featureName);
        return $this->setFlag($featureName, !$currentState, $userId);
    }

    /**
     * Get all feature flags
     */
    public function getAllFlags(): array
    {
        return Cache::remember(
            'all_feature_flags',
            self::CACHE_TTL,
            function () {
                return FeatureFlag::orderBy('name')->get()->toArray();
            }
        );
    }

    /**
     * Create or update a feature flag
     */
    public function createOrUpdate(string $name, string $description, bool $isEnabled = false, ?int $userId = null): FeatureFlag
    {
        return FeatureFlag::updateOrCreate(
            ['name' => $name],
            [
                'description' => $description,
                'is_enabled' => $isEnabled,
                'updated_by' => $userId,
                'created_by' => $userId
            ]
        );
    }

    /**
     * Set flag state
     */
    private function setFlag(string $featureName, bool $enabled, ?int $userId = null): bool
    {
        try {
            $flag = FeatureFlag::where('name', $featureName)->first();
            
            if (!$flag) {
                $flag = FeatureFlag::create([
                    'name' => $featureName,
                    'description' => "Auto-created feature flag for {$featureName}",
                    'is_enabled' => $enabled,
                    'created_by' => $userId,
                    'updated_by' => $userId
                ]);
            } else {
                $flag->update([
                    'is_enabled' => $enabled,
                    'updated_by' => $userId
                ]);
            }

            return true;
        } catch (\Exception $e) {
            Log::error("Failed to set feature flag {$featureName}: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Clear all feature flag cache
     */
    public function clearCache(): void
    {
        $flags = FeatureFlag::all();
        foreach ($flags as $flag) {
            Cache::forget("feature_flag_{$flag->name}");
        }
        Cache::forget('all_feature_flags');
    }
}
```

## 4. Helper Function and Facade

```php
<?php
// app/Helpers/FeatureFlag.php

if (!function_exists('feature')) {
    function feature(string $name): bool
    {
        return app(\App\Services\FeatureFlagService::class)->isEnabled($name);
    }
}
```

```php
<?php
// app/Facades/FeatureFlag.php

namespace App\Facades;

use Illuminate\Support\Facades\Facade;

class FeatureFlag extends Facade
{
    protected static function getFacadeAccessor()
    {
        return \App\Services\FeatureFlagService::class;
    }
}
```

## 5. Admin Controller

```php
<?php
// app/Http/Controllers/Admin/FeatureFlagController.php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FeatureFlag;
use App\Services\FeatureFlagService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class FeatureFlagController extends Controller
{
    private FeatureFlagService $featureFlagService;

    public function __construct(FeatureFlagService $featureFlagService)
    {
        $this->featureFlagService = $featureFlagService;
        $this->middleware('auth');
        $this->middleware('admin'); // Assuming you have admin middleware
    }

    public function index()
    {
        $flags = FeatureFlag::with(['creator', 'updater'])
            ->orderBy('name')
            ->paginate(20);

        return view('admin.feature-flags.index', compact('flags'));
    }

    public function create()
    {
        return view('admin.feature-flags.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255|unique:feature_flags,name',
            'description' => 'nullable|string|max:1000',
            'is_enabled' => 'boolean'
        ]);

        $this->featureFlagService->createOrUpdate(
            $request->name,
            $request->description ?? '',
            $request->boolean('is_enabled'),
            Auth::id()
        );

        return redirect()->route('admin.feature-flags.index')
            ->with('success', 'Feature flag created successfully.');
    }

    public function edit(FeatureFlag $featureFlag)
    {
        return view('admin.feature-flags.edit', compact('featureFlag'));
    }

    public function update(Request $request, FeatureFlag $featureFlag)
    {
        $request->validate([
            'name' => 'required|string|max:255|unique:feature_flags,name,' . $featureFlag->id,
            'description' => 'nullable|string|max:1000',
            'is_enabled' => 'boolean'
        ]);

        $featureFlag->update([
            'name' => $request->name,
            'description' => $request->description,
            'is_enabled' => $request->boolean('is_enabled'),
            'updated_by' => Auth::id()
        ]);

        return redirect()->route('admin.feature-flags.index')
            ->with('success', 'Feature flag updated successfully.');
    }

    public function toggle(FeatureFlag $featureFlag)
    {
        $this->featureFlagService->toggle($featureFlag->name, Auth::id());

        return response()->json([
            'success' => true,
            'is_enabled' => $featureFlag->fresh()->is_enabled
        ]);
    }

    public function destroy(FeatureFlag $featureFlag)
    {
        $featureFlag->delete();

        return redirect()->route('admin.feature-flags.index')
            ->with('success', 'Feature flag deleted successfully.');
    }

    public function clearCache()
    {
        $this->featureFlagService->clearCache();

        return redirect()->route('admin.feature-flags.index')
            ->with('success', 'Feature flag cache cleared successfully.');
    }
}
```

## 6. Admin Views

### Index View
```blade
{{-- resources/views/admin/feature-flags/index.blade.php --}}

@extends('layouts.admin')

@section('title', 'Feature Flags')

@section('content')
<div class="container-fluid">
    <div class="row">
        <div class="col-12">
            <div class="card">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <h3 class="card-title">Feature Flags</h3>
                    <div>
                        <a href="{{ route('admin.feature-flags.create') }}" class="btn btn-primary">
                            <i class="fas fa-plus"></i> Add Feature Flag
                        </a>
                        <form method="POST" action="{{ route('admin.feature-flags.clear-cache') }}" class="d-inline">
                            @csrf
                            <button type="submit" class="btn btn-outline-secondary">
                                <i class="fas fa-sync"></i> Clear Cache
                            </button>
                        </form>
                    </div>
                </div>

                <div class="card-body">
                    @if(session('success'))
                        <div class="alert alert-success alert-dismissible fade show">
                            {{ session('success') }}
                            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                        </div>
                    @endif

                    <div class="table-responsive">
                        <table class="table table-striped">
                            <thead>
                                <tr>
                                    <th>Name</th>
                                    <th>Description</th>
                                    <th>Status</th>
                                    <th>Created By</th>
                                    <th>Updated At</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                @forelse($flags as $flag)
                                    <tr>
                                        <td>
                                            <code>{{ $flag->name }}</code>
                                        </td>
                                        <td>{{ $flag->description ?: 'No description' }}</td>
                                        <td>
                                            <div class="form-check form-switch">
                                                <input 
                                                    class="form-check-input feature-toggle" 
                                                    type="checkbox" 
                                                    data-flag-id="{{ $flag->id }}"
                                                    {{ $flag->is_enabled ? 'checked' : '' }}
                                                >
                                                <label class="form-check-label">
                                                    <span class="badge bg-{{ $flag->is_enabled ? 'success' : 'secondary' }}">
                                                        {{ $flag->is_enabled ? 'Enabled' : 'Disabled' }}
                                                    </span>
                                                </label>
                                            </div>
                                        </td>
                                        <td>{{ $flag->creator->name ?? 'System' }}</td>
                                        <td>{{ $flag->updated_at->format('M d, Y H:i') }}</td>
                                        <td>
                                            <div class="btn-group" role="group">
                                                <a href="{{ route('admin.feature-flags.edit', $flag) }}" 
                                                   class="btn btn-sm btn-outline-primary">
                                                    <i class="fas fa-edit"></i>
                                                </a>
                                                <form method="POST" 
                                                      action="{{ route('admin.feature-flags.destroy', $flag) }}" 
                                                      class="d-inline"
                                                      onsubmit="return confirm('Are you sure you want to delete this feature flag?')">
                                                    @csrf
                                                    @method('DELETE')
                                                    <button type="submit" class="btn btn-sm btn-outline-danger">
                                                        <i class="fas fa-trash"></i>
                                                    </button>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                @empty
                                    <tr>
                                        <td colspan="6" class="text-center">No feature flags found.</td>
                                    </tr>
                                @endforelse
                            </tbody>
                        </table>
                    </div>

                    {{ $flags->links() }}
                </div>
            </div>
        </div>
    </div>
</div>

@push('scripts')
<script>
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.feature-toggle').forEach(function(toggle) {
        toggle.addEventListener('change', function() {
            const flagId = this.dataset.flagId;
            const isEnabled = this.checked;
            
            fetch(`/admin/feature-flags/${flagId}/toggle`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    const badge = this.parentElement.querySelector('.badge');
                    if (data.is_enabled) {
                        badge.textContent = 'Enabled';
                        badge.className = 'badge bg-success';
                    } else {
                        badge.textContent = 'Disabled';
                        badge.className = 'badge bg-secondary';
                    }
                } else {
                    // Revert toggle if failed
                    this.checked = !isEnabled;
                    alert('Failed to update feature flag');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                this.checke
