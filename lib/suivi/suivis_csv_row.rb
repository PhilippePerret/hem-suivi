=begin
# 
# Class Suivi::SuivisCSV::Row
# ---------------------------
# Class des instances des rangées du fichier des suivis
# 
=end
module Suivi
class SuivisCSV
class Row

  def initialize(suivi_csv, csv_row)
    @suivi_csv  = suivi_csv
    @csv_row    = csv_row
  end

  # @return la valeur de la propriété +key+ en la prenant dans la
  # rangée CSV originale
  # La clés +key+ peut être exprimée sous forme de Symbol (:key), elle
  # sera alors transformée en 'Key' (chamélisée)
  def [](key)
    @csv_row[key.camelize]
  end

  # --- Données fixes ---
  def id; @id ||= @csv_row['Id'].freeze  end
  def date; @date ||= @csv_row['Date'].freeze end # c'est déjà une Date
  def client_id; @client_id ||= (@csv_row['Cid']||@csv_row['ClientId']).to_i.freeze end
  def transaction_id; @transaction_id ||= @csv_row['Transaction'].freeze end
  def produits_ids; @produits_id ||= @csv_row['Produits'].to_s.split('+').collect{|n|n.to_i}.freeze end

  # --- Données volatiles ---
  # 

  def client
    @client ||= Suivi::Client.get(client_id)
  end

  # @instance [SuivisCSV::TypeTransaction] de la transaction
  # 
  # @note : à ne pas confondre avec une transaction de produit. Ici
  # c'est la définition absolue de la transaction
  # 
  def transaction_type
    @transaction_type ||= SuivisCSV::TypeTransaction.new(self, transaction_id)
  end

  # [Array<Produit>] Liste des produits visés par le suivi
  def produits
    @produits ||= produits_ids.collect { |p| Suivi::Produit.get(p.to_i)}
  end
    

end #/class Row
end #/class SuivisCSV
end #/module Suivi
