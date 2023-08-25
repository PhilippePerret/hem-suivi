module Suivi
class SuiviCSV

  # [Suivi::File] Le fichier CSV suivi
  attr_reader :file

  def initialize(file)
    @file = file
    check_validity if exist?
  end

  # @return true si le fichier de suivi existe
  def exist?
    ::File.exist?(natural_suivi_path)
  end

  # Permet de charger des données de suivi avec un filtre
  # 
  # @param filter [Hash]
  # 
  #   À commencer par la clé :cid qui permet de filtrer seulement
  #   les transactions d'un utilisateur d'id +cid+
  # 
  def load(filter = nil)
    #
    # Préparation du filtre
    # 
    filter ||= {}
    filter.merge!(cid: [filter[:cid]]) if filter[:cid] && !filter[:cid].is_a?(Array)

    #
    # Relève de la liste
    # 
    options = {headers: true, converters: %i[numeric date]}
    CSV.foreach(path, **options).select do |row|
      next if filter[:cid] && !filter[:cid].include?(row['Cid'])
      true
    end
  end

  def folder
    @folder ||= ::File.dirname(path)
  end

  def path
    @path ||= natural_suivi_path
  end

  def natural_suivi_path
    @natural_suivi_path ||= ::File.join(file.folder, "#{file.affixe}_suivi.csv")
  end


  private

    # Vérifie la validité du fichier de suivi s'il existe
    def check_validity
      parse_for_comments
      @path_to_transactions || raise(SuiviError.new(ERRORS[:suivi_csv][:requires_transactions_path] % path))
      @path_to_products     || raise(SuiviError.new(ERRORS[:suivi_csv][:requires_transactions_path] % path))
      transactions_exist?   || raise(SuiviError.new(ERRORS[:suivi_csv][:transactions_file_unfound] % {path:path, tpath:@path_to_transactions}))
      products_exist?       || raise(SuiviError.new(ERRORS[:suivi_csv][:products_file_unfound] % {path:path, tpath:@path_to_products}))
    end

    def transactions_exist?
      ::File.exist?(@path_to_transactions)
    end

    def products_exist?
      ::File.exist?(@path_to_products)
    end

    def parse_for_comments
      ::File.foreach(path).each_with_index do |line, idx|
        next if idx == 0
        next unless line.start_with?('#')
        if line.start_with?('# Transactions ')
          @path_to_transactions = define_absolute_path(line.split(' ')[2].strip)
        elsif line.start_with?('# Produits')
          @path_to_products = define_absolute_path(line.split(' ')[2].strip)
        end
      end
    end

    def define_absolute_path(relpath)
      if ::File.exist?(relpath)
        relpath
      elsif ::File.exist?(::File.join(folder,relpath))
        #
        # Dans le dossier du fichier de suivi
        # 
        ::File.join(folder,relpath)
      elsif ::File.exist?(::File.join(file.folder,relpath))
        #
        # Dans le dossier du fichier suivi
        # 
        ::File.join(file.folder,relpath)
      end
    end
end #/class SuiviSCSV
end #/module Suivi
