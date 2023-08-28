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


  def parse_products_and_transaction_type
    SuiviCSV::TypeTransaction.init
    csv_opts = {headers: true, converters: %i[numeric date]}
    CSV.foreach(@path_to_transactions, **csv_opts) do |row|
      Suivi::TypeTransaction.add_with_row(row)
    end
    Suivi::Produit.init
    csv_opts = {headers: true, converters: %i[numeric date]}
    CSV.foreach(@path_to_products, **csv_opts) do |row|
      Suivi::Produit.add_with_row(row)
    end
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
  # @param options [Hash]
  # 
  #   Pour définir des paramètres de retour
  # 
  #   @option sort [Sym] Pour classer la liste (:asc, :desc)
  # 
  def find_rows(filter = nil, options = nil)
    #
    # Préparation du filtre
    # (on le simplifie)
    #  
    filter ||= {}
    #
    filter.merge!(produit: filter.delete(:produits)) if filter.key?(:produits)
    filter.merge!(client: filter.delete(:clients)) if filter.key?(:clients)
    filter.merge!(client: filter.delete(:cid)) if filter.key?(:cid)
    filter.merge!(transaction: filter.delete(:transactions)) if filter.key?(:transactions)

    # Préparation des options
    # 
    options ||= {}

    puts "-> SuivisCSV#find_rows"
    puts "filter: #{filter}"

    #
    # Relève la liste des suivis passant le filtre
    # 
    csv_opts = {headers: true, converters: %i[numeric date]}
    rows = CSV.foreach(path_prov, **csv_opts).select do |row|
      #
      # Filtre par le ou les clients
      # 
      if filter.key?(:client)
        next unless match_against?(row, 'Cid', filter[:client])
      end
      #
      # Filtre par la ou les transactions
      # 
      if filter.key?(:transaction)
        next unless match_against?(row, 'Transaction', filter[:transaction])
      end

      #
      # Filtre par le ou les produits
      #
      if filter.key?(:produit)
        next unless match_against?(row, 'Produits', filter[:produit])
      end

      true
    end.collect do |row|
      SuivisCSV::Row.new(self, row)
    end

    #
    # Classement éventuel de la liste
    # 
    if options[:sort]
      case options[:sort]
      when :asc then  rows.sort! { |a, b| a.date <=> b.date }
      else            rows.sort! { |a, b| b.date <=> a.date }
      end
    end

    #
    # Groupement éventuel de la liste
    # 
    if options.key?(:group_by)
      rows = group_rows_by(rows, options[:group_by])
    end

    return rows
  end
  alias :load :find_rows

  # Méthode permettant de grouper les résultats par la clé +by_key+
  # qui peut être :client, :produit ou :transaction
  # 
  # 
  def group_rows_by(rows, by_key)
    table = {}
    if [:client, 'Client','client'].include?(by_key)
      by_key = :client_id 
    elsif [:transaction, 'transaction','Transaction'].include?(by_key)
      by_key = :transaction_id
    elsif [:produit, 'Produit','Produits'].include?(by_key)
      by_key = :produit_id
    end
    #
    # La classe pour la clé de table
    # 
    btable = {sujet:[], clients:[], transactions:[], produits:[], rows:[]}
    classe, blank_table = case by_key
    when :client_id then
      btable.delete(:clients)
      [Suivi::Client, btable]
    when :transaction_id then 
      btable.delete(:transactions)
      [Suivi::Transaction, btable]
    when :produit_id then 
      btable.delete(:produits)
      [Suivi::Produit, btable]
    end
    #
    # On boucle sur toutes les rangées
    # 
    rows.each do |row| # SuivisCSV::Row
      value_for_key = row.send(by_key)
      #
      # Pour avoir une clé qui soit une instance de l'objet
      # (un client, un produit ou une transaction)
      # 
      real_key_value = classe.get(value_for_key)
      #
      # On initie le groupe pour la valeur +value_for_key+ s'il
      # n'existe pas encore
      # 
      unless table.key?(real_key_value)
        btable = blank_table.dup.merge!(sujet: real_key_value)
        table.merge!(real_key_value => btable)
      end
      #
      # On ajoute cette rangée
      # 
      table[real_key_value][:rows] << row

      #
      # On traite le ou les produits que traite cette rangée
      # 
      row.produits.each do |produit|
        #
        # On doit ajouter les produits
        # (sauf groupement par produit)
        # 
        unless by_key == :produit
          table[real_key_value][:produits] << produit unless table[real_key_value][:produits].include?(produit)
        end

        #
        # On doit ajouter les transactions (une par produit)
        # (sauf groupement par transaction)
        # 
        unless by_key == :transaction
          transaction = Suivi::Transaction.new(row, produit)
          table[real_key_value][:transactions] << transaction
        end

      end

      #
      # On doit ajouter les clients
      # (sauf groupement par client)
      # 
      unless by_key == :client
        table[real_key_value][:clients] << row.client unless table[real_key_value][:clients].include?(row.client)
      end

    end
    return table
  end

  # Méthode principale qui va voir si une rangée du fichier de suivi
  # correspond à +expected+ sur la clé (nom colonne) +key+
  # 
  # C'est une partie seulement du filtre qui ne concerne qu'une seule
  # colonne.
  # 
  # @return true si la valeur +expected[:id]+ contient ou est égale à
  # la valeur de la colonne +key+ de la rangée CSV +row+ et si les
  # autres conditions contenues dans +expected+ sont remplies
  def match_against?(row, key, expected)
    expected_id = expected[:id]
    if expected.is_a?(Array)
      expected_id.include?(row[key]) || return
    else
      row[key].to_s == expected_id.to_s || return
    end

    # --- Test des autres conditions ---
    # 
    row_date = row['Date'].to_time

    if expected.key?(:before)
      return false if row_date > expected[:before]
    end

    if expected.key?(:after)
      return false if row_date < expected[:after]
    end

    return true # ok
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
