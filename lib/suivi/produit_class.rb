require_relative 'CSVObject'
module Suivi
class Produit < CSVObject
class << self

  # @return le produit [Suivi::Produit] d'identifiant produit_id, 
  # dans le contexte du fichier de suivi +suivi_file+
  # 
  # @note
  #   En utilisation normale, un fichier principal (de clients) est
  #   envoyé pour initialisation d'un Suivi::File. Cette initialisa-
  #   tion comporte le parse du fichier (qui donnera les "clients")
  #   ainsi que la définition des produits et des types de transac-
  #   tions. 
  #   Donc, dans ce cas normal, on n'a pas besoin de fournir le
  #   fichier principal ici.
  #   Mais il se peut qu'on ait besoin parfois d'appeler cette 
  #   méthode en dehors de toute autre utilisation et, dans ce
  #   cas, il faut transmettre en second argument le chemin d'accès
  #   au fichier principal (des clients)
  # 
  def get(id, main_file = nil)
    unless main_file.nil?
      Suivi::File.new(main_file) # Ce qui provoquera l'initialisation de tout
    end
    @items[id]
  end


  # @return les produits relatifs au fichier principal (de clients)
  # +main_file+ qui répond au filtre +filter+ en respectant les
  # options +options+
  # 
  def find(main_file, filter, options = nil)
    main_file = Suivi::File.new(main_file) unless main_file.is_a?(Suivi::File)
    options ||= {}
    options.merge!(group_by: :produit)
    main_file.find_suivis()
  end

end #/<< self Produit
end #/class Produit
end #/module Suivi
