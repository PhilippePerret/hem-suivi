module Suivi
class File
  attr_reader :path
  def initialize(path, options = nil)
    @options = defaultize_options(options)
    check_path(path)
    @path = path
  end


  # @instance [Suivi::SuivisCSV] du fichier de suivi, qu'il existe 
  # déjà ou non.
  def suivi
    @suivi ||= Suivi::SuivisCSV.new(self)
  end

  # @return true si le fichier courant est suivi
  def has_suivi?
    suivi.exist?
  end


  def defaultize_options(options)
    options ||= {}
    options.key?(:col_spec) || options.merge!(col_spec: ',')
    return options
  end

  def col_spec
    @col_spec ||= @options[:col_spec]
  end

  def affixe
    @affixe ||= ::File.basename(path,::File.extname(path)).freeze
  end

  def folder
    @folder ||= ::File.dirname(path).freeze
  end

  private


    # Vérification du fichier
    def check_path(pth)
      ::File.exist?(pth)            || raise(ArgumentError.new(ERRORS[:file][:unknown_path] % pth))
      ::File.extname(pth) == '.csv' || raise(ArgumentError.new(ERRORS[:file][:bad_extension] % pth))
      has_key_id?(pth)              || raise(SuiviError.new(ERRORS[:file][:key_id_required] % pth))
    end

    # @return true si l'entête contient 'Id'
    def has_key_id?(pth)
      ::File.foreach(pth) do |line|
        return line.strip.split(col_spec).include?('Id')
      end
    end
end
end#/module Suivi
