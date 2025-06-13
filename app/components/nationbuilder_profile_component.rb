class NationbuilderProfileComponent < Catalyst::BaseComponent
  include ActionView::Helpers::DateHelper

  # Configuration for icon mappings
  ICON_MAPPINGS = {
    "phone" => "phone",
    "tag" => "tag",
    "refresh" => "arrow-path"
  }.freeze
  
  DEFAULT_ICON = "information-circle".freeze

  # Make Current available in the component
  delegate :current_user, to: :helpers

  def current_user
    Current.user
  end
  def initialize(user:, **options)
    @user = user
    super(**options)
  end

  def render?
    user.nationbuilder_user? && user.has_nationbuilder_profile_data?
  end

  private

  attr_reader :user

  def profile_sections
    sections = []

    sections << contact_info_section if has_contact_info?
    sections << tags_section if has_tags?
    sections << sync_info_section if has_sync_info?

    sections
  end

  def contact_info_section
    {
      title: "Contact Information",
      icon: "phone",
      items: contact_info_items
    }
  end

  def tags_section
    {
      title: "Tags",
      icon: "tag",
      items: tag_items
    }
  end

  def sync_info_section
    {
      title: "Sync Information",
      icon: "refresh",
      items: sync_info_items
    }
  end

  def contact_info_items
    items = []

    if user.nationbuilder_phone.present?
      items << {
        label: "Phone",
        value: user.nationbuilder_phone,
        type: "text"
      }
    end

    items
  end

  def tag_items
    user.nationbuilder_tags.map do |tag|
      {
        label: tag,
        type: "tag"
      }
    end
  end

  def sync_info_items
    items = []

    if last_synced_at
      items << {
        label: "Last synced",
        value: time_ago_in_words(last_synced_at) + " ago",
        type: "text"
      }
    end

    items << {
      label: "NationBuilder ID",
      value: user.nationbuilder_uid,
      type: "text"
    }

    items
  end

  def has_contact_info?
    user.nationbuilder_phone.present?
  end

  def has_tags?
    user.nationbuilder_tags.any?
  end

  def has_sync_info?
    true
  end

  def last_synced_at
    return nil unless user.nationbuilder_profile_data

    sync_time = user.nationbuilder_profile_data["last_synced_at"]
    return nil unless sync_time

    Time.parse(sync_time)
  rescue ArgumentError
    nil
  end

  def heroicon_name(icon)
    ICON_MAPPINGS[icon] || DEFAULT_ICON
  end
end
