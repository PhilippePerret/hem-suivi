module Suivi
class CSVObject

  class << self

    # @return l'instance d'identifiant +id+
    # 
    def get(id)
      @items[id] || raise(SuiviError.new("L'instance ##{id} de classe #{self.name} est inconnue…"))
    end

    def init
      @items = {}
    end

    def add_with_row(row)
      item = self.new(row.to_hash)
      @items.merge!(item.id => item)
    end

  end #/<< self class 

  # --- INSTANCE ---

  def initialize(data)
    @data = data
  end

  # Pour obtenir une donnée à partir de <instance>[<key>]
  def [](key)
    @data[key.camelize]
  end

  # --- Pour récupérer n'importe quelle donnée ---

  def method_missing(method_name, *args, &block)
    if (@data.key?(method_name.camelize))
      return @data[method_name.camelize]
    end
    raise NoMethodError.new("Methode #{method_name.inspect} inconnue.")
  end

  # --- Data fixes de tout objet CSV ---

  def id; @data['Id'] end

end #/class Produit
end #/module Suivi
