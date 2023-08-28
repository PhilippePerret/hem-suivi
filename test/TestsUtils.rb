#
# Utilitaires pour les tests
# 

class TestsUtils
class << self

  #
  # Créer un fichier de suivi pour le fichier +fref+ avec les données
  # +data+
  # 
  # @param fref [String]
  # 
  #   Chemin d'accès au nouveau fichier de suivi
  # 
  # @param data [Array]
  # 
  #   Les données. C'est une liste de tables contenant au moins et
  #   seulement {:client, :produits, :transaction, :date}
  #   :client [Integer] Identifiant du client dans le fichier principal
  #   :produits [String] Identifiants des produits séparés par des '+'
  #   :transaction [String] La transaction concernée (doit être définie dans transaction.csv)
  #   :date [String|Date] Soit la date au format "AAAA-MM-JJ", soit la date elle-même
  # 
  # @param options [Hash]
  # 
  #   :transactions_path  [String] Chemin d'accès au fichier de la définition des transactions
  #   :produits_path      [String] Chemin d'accès au fichier des produits
  # 
  def build_suivi_file(fref, data, options = nil)
    #
    # Options par défaut
    # 
    options ||= {}
    options.key?(:transactions_path) || options.merge!(transactions_path: 'transactions.csv')
    options.key?(:produits_path) || options.merge!(produits_path: 'produits.csv')
    #
    # Chemin d'accès au fichier des suivis (en fonction du fichier
    # de référence)
    # (on l'écrase s'il existe déjà)
    # 
    suivi_path = ::File.join(::File.dirname(fref), "#{::File.basename(fref,::File.extname(fref))}_suivi.csv")
    ::File.delete(suivi_path) if ::File.exist?(suivi_path)
    #
    # Construction des rangées
    # 
    rows = ["Id,Cid,Produits,Date,Transaction"]
    rows << "# Transactions #{options[:transactions_path]}"
    rows << "# Produits #{options[:produits_path]}"
    data.each_with_index do |h, idx|
      h[:date] = ymd(h[:date]) unless h[:date].is_a?(String)
      rows << "#{idx + 1},#{h[:client]},#{h[:produits]},#{h[:date]},#{h[:transaction]}"
    end
    rows = rows.join("\n")
    #
    # Écriture du fichier final
    # 
    ::File.write(suivi_path, rows)

    return true # ok
  end
end #/<< self
end #/class TestsUtils
