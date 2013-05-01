# coding: utf-8
class String

  def to_underscore!
    g = gsub!(/(.)([A-Z])/,'\1_\2'); d = downcase!
    g || d
  end

  def to_underscore
    dup.tap { |s| s.to_underscore! }
  end

end