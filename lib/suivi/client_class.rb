require_relative 'CSVObject'
module Suivi
class Client < CSVObject
class << self


  # @return la liste des clients du +main_file+ qui ont des transactions
  # répondant au filtre +filtre+ avec les options +options+
  # 
  # @param main_file [String|Suivi::File]
  # 
  #   Chemin d'accès au fichier principal contenant une liste de
  #   client avec leurs paramètres ou son instance Suivi::File qui
  #   a pu être instanciée par Suivi::File.new(main_file)
  # 
  # @param filtre [Hash]
  # 
  #   Définition du filtre. Voir le manuel pour en avoir les
  #   détails.
  # 
  # @param options [Hash]
  # 
  #   Définition du résultat renvoyé.
  # 
  def find(main_file, filtre, options = nil)
    #
    # S'il le faut, il faut transformer le fichier principal en 
    # fichier de suivi Suivi::File
    # 
    main_file = Suivi::File.new(main_file) unless main_file.is_a?(Suivi::File)
    #
    # On récupère tous les suivis correspondant au filtre
    # 
    options ||= {}
    options.merge!(group_by: :client)
    main_file.find_suivis(filtre, options)
  end

end #/<< self Client
end #/class Client
end #/module Suivi
