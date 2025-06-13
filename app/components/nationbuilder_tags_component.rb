class NationbuilderTagsComponent < Catalyst::BaseComponent
  # Configuration constants
  DEFAULT_TAG_DISPLAY_LIMIT = 10
  
  def initialize(user:, **options)
    @user = user
    super(**options)
  end

  def render?
    user.nationbuilder_user? && user.nationbuilder_tags.any?
  end

  private

  attr_reader :user

  def tags
    user.nationbuilder_tags.sort
  end

  def tag_color(tag)
    # Assign colors based on tag content/type
    case tag.downcase
    when /member|supporter/
      :green
    when /volunteer|activist/
      :blue
    when /donor|contributor/
      :purple
    when /leader|admin/
      :yellow
    when /inactive|former/
      :gray
    else
      :blue
    end
  end

  def tag_display_limit
    DEFAULT_TAG_DISPLAY_LIMIT
  end

  def show_all_tags?
    tags.length <= tag_display_limit
  end

  def visible_tags
    show_all_tags? ? tags : tags.first(tag_display_limit)
  end

  def hidden_tags_count
    return 0 if show_all_tags?
    tags.length - tag_display_limit
  end
end
