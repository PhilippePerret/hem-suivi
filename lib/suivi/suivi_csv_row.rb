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

  # --- Données fixes ---
  def id; @id ||= @csv_row['Id'].freeze  end
  def client_id; @client_id ||= (@csv_row['Cid']||@csv_row['ClientId']).freeze end
  def transaction_id; @transaction_id ||= @csv_row['Transaction'].freeze end
  def produits_ids; @produits_id ||= @csv_row['Produits'].split('+').freeze end

  # --- Données volatiles ---

  # @instance [Transaction] de la transaction
  def transaction
    @transaction ||= SuivisCSV::Transaction.new(self.suivi_csv, transaction_id)
  end

  # [Array<Produit>] Liste des produits visés par le suivi
  def produits
    @produits ||= produits_id.collect { |p| SuivisCSV::Produit.new(self.suivi_csv, p.to_i)}
  end
    

end #/class Row
end #/class SuivisCSV
end #/module Suivi
