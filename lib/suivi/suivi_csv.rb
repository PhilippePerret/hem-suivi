module Suivi
class SuiviCSV

  # [Suivi::File] Le fichier CSV suivi
  attr_reader :file

  def initialize(file)
    @file = file
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
  def load(filter = nil)
    #
    # Préparation du filtre
    # 
    filter ||= {}
    filter.merge!(cid: [filter[:cid]]) if filter[:cid] && !filter[:cid]is_a?(Array)

    #
    # Relève de la liste
    # 
    options = {hearder: true, converters: %i[numeric date]}
    CSV.foreach(path, **options).collect do |row|
      next if filter[:cid] && !filter[:cid].include?(row['Cid'])
    end
  end

  def path
    @path ||= natural_suivi_path
  end

  def natural_suivi_path
    @natural_suivi_path ||= ::File.join(file.folder, "#{file.affixe}_suivi.csv")
  end

end #/class SuiviSCSV
end #/module Suivi
