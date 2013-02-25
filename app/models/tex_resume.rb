class TexResume
  include ActionView::Helpers::TextHelper, I18nHelper, FormattingHelper,
    ActionView::Helpers::TranslationHelper

  TEMPLATE_PATH = File.join(Rails.root, 'app', 'views', 'resumes', 'show.tex.erb')
  LOGO_PATH     = File.join(Rails.root, 'public', 'uploads', 'logo.pdf')
  OUTPUT_DIR    = File.join(Rails.root, 'tmp', 'resumes')

  attr_reader :r, :url, :lang
  attr_accessor :output_dir

  def self.base_name(resume, lang = :en)
    "#{resume.slug}.#{lang}"
  end

  def self.pdf_path(resume, lang = :en)
    File.join(OUTPUT_DIR, "#{TexResume.base_name(resume, lang)}.pdf")
  end

  def self.exists?(resume, lang = :en)
    File.exists?(self.class.pdf_path(resume, lang))
  end

  def initialize(resume, lang = 'en')
    @r = resume
    @lang = lang

    @logo_path = File.size?(LOGO_PATH) ? LOGO_PATH : nil
  end

  def base_name
    self.class.base_name @r, @lang
  end

  def pdf_path
    self.class.pdf_path @r, @lang
  end

  # Renders the resume in TeX format and returns the generated TeX code.
  def to_tex
    ERB.new(IO.read(TEMPLATE_PATH)).result(binding)
  end

  # Renders the resume in TeX and compiles it to PDF (unless there's an existing
  # copy of it newer than the last modification time of the model).
  # Returns an absolute path to the compiled PDF if successful, nil otherwise.
  def to_pdf(force_render = false)
    tex_path = File.join(OUTPUT_DIR, "#{base_name}.tex")
    out = 'error'

    if !force_render && File.size?(pdf_path) && File.mtime(pdf_path) > @r.updated_at
      return pdf_path, 'cached'
    end

    Dir.mkdir(OUTPUT_DIR) unless File.directory?(OUTPUT_DIR)
    Dir.chdir OUTPUT_DIR do
      File.open(tex_path, 'w') do |file|
        file.write to_tex
      end

      File.unlink(pdf_path) if File.file?(pdf_path)

      # Compile tex source twice (to sync AUX file and stuff)
      out = `pdflatex #{tex_path} && pdflatex #{tex_path}`

      return pdf_path, out if File.size?(pdf_path)
    end

    return nil, out
  end

  alias :save :to_pdf

  # Escapes special TeX character sequences in a string.
  def htex(str)
    return str unless str.kind_of? String
    str.blank? ? '' : str.gsub(/\&/, '\\\\&').gsub(/%/, '\\\\%').gsub(/\$/, '\\\\$')
  end
end

module I18n
  class MissingTranslation
    def html_message
      keys.join('.')
    end
  end
end