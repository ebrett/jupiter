# Democrats Abroad Brand Guidelines for Rails/Tailwind Implementation

## Overview
This document extracts key brand elements from the Democrats Abroad 2024 Brand Guidelines for implementation in a Rails application using Tailwind CSS.

## Logo Usage

### Logo Variants Available
- **Primary (Horizontal)**: Default logo for most uses, provides optimum visibility
- **Stacked**: For limited horizontal space, used as social media profile picture
- **Wordmark**: Text-only version when space is limited or visual distractions present
- **White Knockout**: Available for all variants on dark backgrounds

### Logo Rules
- **Clear Space**: Always maintain at least 10px of clear space around logo
- **DO NOT**: Distort, recolor, reorder elements, outline, use colored logo on dark backgrounds, or add country flags

## Color Palette

### Core Brand Colors
```
Navy (Primary): #1F1646 (RGB: 31, 22, 70)
Blue Dark: #003087 (RGB: 0, 48, 135)  
Electric Blue: #00A9E0 (RGB: 0, 169, 224)
Light Blue: #9EADE5 (RGB: 158, 173, 229)
Red (Contrast): #B2292E (RGB: 178, 41, 46)
Gray: #AFB5BF (RGB: 175, 181, 191)
```

### NEW Accent Colors
```
Yellow: #FFE16A (RGB: 255, 225, 106)
Cream: #EDD9BE (RGB: 237, 217, 190)  
Green: #8AD594 (RGB: 138, 213, 148)
Coral: #FF787E (RGB: 255, 120, 126)
Purple: #9271B2 (RGB: 146, 113, 178)
Sky Blue: #B9DEFF (RGB: 185, 222, 255)
```

### Caucus Colors
Each caucus has specific brand colors:
- **Women's Caucus**: #EB008B (Magenta)
- **Black Caucus**: #D72426 (Red)
- **Disability Caucus**: #1B75BB (Blue)
- **Hispanic Caucus**: #470054 (Purple)
- **Youth Caucus**: #5263A4 (Blue)
- **Environment & Climate**: #629241 (Green)
- **AAPI Caucus**: #E25728 (Orange)
- **Veterans & Military**: #7793A3 (Blue-gray)
- **Seniors Caucus**: #FFC813 (Yellow)
- **Progressive Caucus**: #00B7AA (Teal)
- **LGBTQ+ Caucus**: Uses 5 rainbow colors (Red, Orange, Yellow, Green, Blue)

## Typography

### Primary Fonts
- **Overpass**: Versatile use for headlines, subheadings, body text
  - Available weights: Thin, Extra-Light, Light, Regular, Semi-Bold, Bold, Extra-Bold, Black
- **Oswald**: Headlines and larger subheadings for more information

### Canva Alternative Fonts (for free users)
- **Open Sans Extra Bold**: High impact headings, short calls to action
- **Courgette**: Casual and personable headings
- **Overpass**: Still recommended for versatile use

### Reserved Fonts
- **Interstate**: Used exclusively for DA logo, do not use elsewhere
- **Vote from Abroad**: Custom font for VFA materials only

## Implementation Guidelines

### Rails Application Structure
1. Configure Tailwind with custom DA color palette
2. Create view helpers for consistent logo rendering
3. Implement typography helpers for brand-compliant text
4. Build reusable components for buttons, cards, and navigation

### Key Implementation Points
- Use semantic color names (da-navy, da-blue, etc.) in Tailwind config
- Create helpers for logo variants and caucus-specific branding
- Maintain 10px clear space around logos
- Implement white knockout versions for dark backgrounds
- Use brand fonts consistently across the application

### File Structure Recommendations
```
app/
  helpers/
    democrats_abroad_brand_helper.rb
  assets/
    images/
      logos/ (store logo variants)
  views/
    shared/
      _da_logo.html.erb
      _da_navigation.html.erb
```

### Tailwind Configuration
The custom Tailwind config includes:
- All brand colors as custom color classes
- Font family definitions
- Custom spacing for logo clear space
- Background gradients using brand colors

## Content Types
The brand guidelines mention creating graphics for:
- Quotes and testimonials
- Events and announcements  
- GOTV (Get Out The Vote) campaigns
- Training materials
- Social media content
- Delegate spotlights

## Resources
- **Logo Repository**: DA Wiki (democratsabroad.org wiki)
- **Contact**: comms@democratsabroad.org
- **Guidelines**: Request logo files rather than creating custom artwork

## Brand Goals
- Build cohesiveness across all DA design and social media assets
- Provide tools for content creators throughout the organization
- Ensure clear recognition as Democrats Abroad across all communications
- Align country committees, chapters, caucuses, and global teams under unified brand