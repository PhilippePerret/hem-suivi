module Suivi
class File
  attr_reader :path
  def initialize(path, options = nil)
    @options = defaultize_options(options)
    check_path(path)
    @path = path
    parse
    #
    # Si ce fichier principal possède un fichier de suivi (valide)
    # on récupère les produits et les types de transaction qu'il
    # contient.
    # 
    suivi.parse_products_and_transaction_type if has_suivi?
  end

  # Pour récupérer tous les clients
  # 
  def parse
    Suivi::Client.init
    csv_opts = {headers: true, converters: %i[numeric date]}
    CSV.foreach(path, **csv_opts) do |row|
      Suivi::Client.add_with_row(row)
    end
  end

  # @param options [Hash]
  # 
  #   Les options pour la valeur retournée
  #   @option :as     :transaction
  def find_suivis(filter, options = nil)
    options ||= {}
    if has_suivi?
      res = suivi.find_rows(filter, options)
      if options[:as] == :transaction
        #
        # Il faut transformer la liste des résultats en instance
        # Suivi::Transaction
        # 
        liste = []
        res.each do |row|
          row.produits.each do |produit|
            liste << Suivi::Transaction.new(row, produit)
          end
        end
        return liste
      end

      return res
    else
      return []
    end
  end

  # Raccourcis
  def find_produits(filter, options = nil)
    Suivi::Produit.find(filter, options)
  end
  def find_clients(filter, options = nil)
    Suivi::Client.find(filter, options)
  end
  def find_transactions(filter, options = nil)
    Suivi::Transaction.find(filter, options)
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
