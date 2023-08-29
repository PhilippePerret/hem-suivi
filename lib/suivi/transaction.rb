module Suivi
class Transaction

  class << self

    def find(main_file, filtre, options = nil)
      main_file = Suivi::File.new(main_file) unless main_file.is_a?(Suivi::File)
      options ||= {}
      main_file.find_suivis(filtre, options).collect do |row|
        # Les rangées peuvent contenir plusieurs produits, il faut
        # faire une transaction par produit
        row.produits.collect do |produit|
          self.new(row, produit)
        end
      end.flatten
    end


  end #/<< self class Suivi::Transaction

  # Instanciation d'une transaction
  # 
  # @param row [SuivisCsv::Row]
  # 
  #   La rangée du fichier de suivi qui contient la transaction en
  #   questions. C'est une instance SuivisCsv::Row
  # 
  # @param produit [SuivisCSV::Produit]
  # 
  #   Instance du produit concerné (note : son identifiant se 
  #   trouve dans la donnée 'Produits' de la rangé row)
  # 
  #   @note : il faut fournir le produit car la ligne +row+ peut
  #   concerner plusieurs produits.
  # 
  def initialize(row, produit)
    @row      = row
    @produit  = produit
  end


  def inspect
    "<<Suivi::Transaction Client:#{@row.client_id} Produit:#{@produit.id}>>"
  end

  def [](key)
    @row[key] || @produit[key]
  end

  def date; @row['Date'] end
  def produit_id; produit.id end
  def produit; @produit  end
  def client_id; @row['Cid']||@row['Client'] end
  def client; @client ||= Suivi::Client.get(client_id) end



end #/class Transaction
end #/module Suivi
