=begin
# 
# Class Suivi::SuivisCSV
# -------------------
# Class qui gère le fichier csv de suivi.Chaque ligne de suivi
# produit un item SuivisCSV::Row
# 
=end
module Suivi
class SuivisCSV

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
    # Relève la liste des suivis passant le filtre
    # 
    options = {headers: true, converters: %i[numeric date]}
    CSV.foreach(path_prov, **options).select do |row|
      next if filter[:cid] && !filter[:cid].include?(row['Cid'])
      true
    end.collect do |row|
      SuivisCSV::Row.new(self, row)
    end
  end

  def folder
    @folder ||= ::File.dirname(path)
  end

  def path
    @path ||= natural_suivi_path
  end

  # Le chemin d'accès au fichier qui contiendra seulement les lignes
  # valides (pas les commentaires)
  def path_prov
    @path_prov ||= begin
      ::File.join(folder, ".#{file.affixe}_suivi.csv").tap do |f|
        ::File.delete(f) if ::File.exist?(f)
      end
    end
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

    # On retire les commentaires du fichier de suivi et on en profite
    # pour récupérer le fichier de la définitions des transactions et
    # des produits.
    def parse_for_comments
      ref = ::File.open(path_prov,'a')
      begin
        ::File.foreach(path).each_with_index do |line, idx|
          if idx == 0
            ref.write(line)
            next 
          end
          if line.start_with?('#')
            if line.start_with?('# Transactions ')
              @path_to_transactions = define_absolute_path(line.split(' ')[2].strip)
            elsif line.start_with?('# Produits')
              @path_to_products = define_absolute_path(line.split(' ')[2].strip)
            end
          else
            ref.write(line)
          end
        end
      ensure
        ref.close
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
