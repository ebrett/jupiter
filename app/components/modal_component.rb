class ModalComponent < ViewComponent::Base
  def initialize(id:, title: nil, size: :md, closeable: true)
    @id = id
    @title = title
    @size = size
    @closeable = closeable
  end

  private

  attr_reader :id, :title, :size, :closeable

  def size_classes
    case size
    when :sm
      "max-w-md"
    when :lg
      "max-w-2xl"
    when :xl
      "max-w-4xl"
    else
      "max-w-lg"
    end
  end

  def modal_classes
    [
      "fixed inset-0 z-50 overflow-y-auto",
      "flex items-center justify-center min-h-screen px-4",
      "bg-black bg-opacity-50"
    ].join(" ")
  end

  def dialog_classes
    [
      "relative bg-white rounded-lg shadow-xl",
      "w-full #{size_classes}",
      "transform transition-all"
    ].join(" ")
  end
end
