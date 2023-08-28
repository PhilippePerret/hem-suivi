module Suivi
class Transaction

  # Instanciation d'une transaction
  # 
  # @param row [SuivisCsv::Row]
  # 
  #   La rangée du fichier de suivi qui contient la transaction en
  #   questions.
  # 
  # @param produit [SuivisCSV::Produit]
  # 
  #   Instance du produit concerné (note : son identifiant se 
  #   trouve dans la donnée 'Produits' de la rangé row)
  # 
  def initialize(row, produit)
    @row      = row
    @produit  = produit
  end


  def inspect
    "<<Suivi::Transaction Client:#{@row.client_id} Produit:#{@produit.id}>>"
  end

end #/class Transaction
end #/module Suivi
