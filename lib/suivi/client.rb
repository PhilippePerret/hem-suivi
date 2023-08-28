#
# Class Suivi::Client
# -------------------
# Gestion d'un client dans le programme de suivi
# On retrouve le client premièrement dans le fichier principal
# contenant les données par rangées CSV de ces clients.
# 
module Suivi
class Client

  def initialize(data)
    # puts "data: #{data.inspect}"
    @data = data
  end

  # --- Data fixes ---
  # 
  def id; @data['Id'] end
  def patronyme; @data['Patronyme'] end
  def mail; @data['Mail'] end
  def sexe; @data['Sexe'] end

end #/class Client
end #/module Suivi
