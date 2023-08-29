# Tutoriel pour le gem ‘suivi’



Dans ce tutoriel, nous allons créer un filtre pour relever les clients d’une maison d’éditions qui doivent être contactés, suite à leur achat d’un ou de plusieurs livres, pour une enquête de satisfaction. Cette enquête doit être envoyée tous les mois, mais ne pas être envoyée deux fois (un autre message de rappel sera plutôt envoyé, mais pas dans ce tutoriel).

### Pré-requis

Pour procéder à cette opération, nous avons besoin d’un fichier de client CSV. Ce fichier de nom **`clients_icare.csv`** porte l’entête suivant, définissant les colonnes utiles :

~~~csv
Id,Patronyme,Mail,Fonction,Adresse,Mobile,Note
~~~

Parallèlement à ce fichier, un fichier de suivi qui porte le nom *naturel*, c’est-à-dire **`clients_icare_suivi.csv`** et qui se trouve donc au même niveau que le fichier des clients. Ce fichier de suivi, pour être conforme, doit définir au moins les colonnes et les commentaires :

~~~csv
Id,Transaction,Date,Cid,Produits
# Transactions transactions.csv
# Produits livres.csv
~~~

Les deux lignes de commentaires permettent de définir le chemin relatif aux fichiers de données. On a donc d’abord le fichier **`transactions.csv`** (au même niveau que le fichier principal `clients_icare.csv`) qui définit le *type* de transactions :

~~~csv
Id,Name,Description
ACHAT,Achat,Quand un client achète un livre à la maison d'édition
ENQUETE,Enquête de satisfaction,Quand on envoie au client l'enquête de satisfaction
~~~

Et l’on a le fichier **`produits.csv`** au même niveau que le fichier principal lui aussi, qui définit les livres de la maison d’éditions :

~~~csv
Id,Titre,Auteur,Description
1,Savoir rédiger et présenter son scénario,Philippe PERRET
2,Des souris et des hommes, John STEINBECK
3,Les Misérables,Émile ZOLA
4,Notre Dame de Paris,Victor HUGO
etc.
~~~



### Détail de l’opération

Nous voulons donc obtenir la liste des clients devant recevoir l’enquête de satisfaction, ainsi que les livres concernés. Il faut tenir compte du fait qu’un client peut avoir acheté des livres avant, en ayant déjà reçu l’enquête, donc il faut qu’elle soit vraiment centrée sur les nouveaux livres.

Avec **Suivi**, on procède par requêtes simple successives. Il n’est pas possible, dans un tel cas de procéder d’un seul coup. Mais il existe toujours plusieurs moyens d’arriver à ses fins. Les voicis

### Premier moyen

Nous allons procéder de cette manière :

* Nous allons relever les transactions concernant les achats effectués dans l’année mais vieux de plus de deux mois.
* Nous allons relever les transactions concernant les enquêtes de satisfaction de l’année.
* Nous retirons de la première liste les transactions pour un couple client-livre qui appartiennent à la seconde liste.
* Nous les groupons par client pour obtenir ceux qui doivent être contactés et pour quels livres.

**Relève des transactions sur les achats**

~~~ruby
require 'suivi'
require 'clir'

# Fichier principal
# @note
# 	On utilise '__dir__' car le script va être lancé depuis le
#   dossier contenant le fichier.
main_file = File.join(__dir__, 'clients_icare.csv')

# Le premier filtre
filtre_achats = {
  transaction: 'ACHAT', # Transaction de type 'ACHAT'
  before:Time.now - 60.days, # effectuée il y a 2 mois au moins
  after: Time.now - 365.days # pour accélérer les choses
}

# On relève les transactions
transactions_achats = Suivi::Transaction.find(main_file, filtre_achats)
# => Liste de toutes les instances Suivi::Transaction qui matchent
#    le filtre
~~~

Puis on poursuit pour obtenir les transactions d’envoi de l’enquête (dans le même fichier ruby) :

~~~ruby
# Second filtre
# Noter qu'il n'y a plus de condition :before, puisque l'enquête
# a pu être envoyée récemment.
filtre_enquetes = {
  transaction: 'ENQUETE',
  after: Time.now - 365.days # pour accélérer
}

# Relève des transactions
transactions_enquetes = Suivi::Transaction.find(main_file, filtre_enquetes)
# => Liste des instances Suivi::Transaction correspondantes.
~~~

Maintenant, on va devoir retirer de `transactions_achats` toutes les livres-clients qui ont reçu l’enquête de satisfaction. Si un client #4 a déjà reçu l’enquête pour le livre « Notre Dame de Paris » il ne faut plus lui envoyer. Pour simplifier l’opération, on va faire une table avec en clé l’identifiant du client et en valeur la liste des livres pour lesquels l’enquête a déjà été reçue.

~~~ruby
# Table des livres pour lesquels l'enquête a déjà été envoyée,
# par client
livres_enquete_de = {}
transactions_enquetes.each do |transaction|
  # Si la table ne connait pas le client de cette transaction,
  # on ajoute un élément pour lui.
  unless livres_enquete_de.key?(transaction.client_id)
    livres_enquete_de.merge!(transaction.client_id => [])
  end
  # Et on met l'identifiant du livre
  livres_enquete_de[transaction.client_id] << transaction.produit_id
end
~~~

On peut maintenant retirer de la liste des achats, tous les livres-clients pour lesquels l’enquête a déjà été reçue. Cela donne (toujours à la suite du fichier ruby) :

~~~ruby
transactions_pour_enquetes = transactions_achats.reject do |transaction|
  # Pour être rejetée la transaction, il faut :
  # … que livres_enquete_de connaisse le client
  livres_enquete_de.key?(transaction.client_id) &&
  # … que la liste des livres "enquêtés" contienne son livre
  livres_enquete_de[transaction.client_id].include?(transaction.produit_id)
end
# => Liste des transactions concernant les livres non "enquêtés"
~~~

<a name="group-by-client"></a>

**Grouper par client**

Il ne nous reste plus qu’à grouper les résultats par client, pour connaitre, pour chaque client, les livres qui vont devoir être « enquêtés ».

~~~ruby
enquetes_requises_par_clients = {}
transactions_pour_enquetes.each do |transaction|
  client = transaction.client
  unless enquetes_requises_par_clients.key?(client)
    enquetes_requises_par_clients.merge!(client => [])
  end
  enquetes_requises_par_clients[client] << transaction.produit
end
# => Table avec en clé l'instance [Suivi::Client] du Client et en
#    valeur la liste des livres [Suivi::Produit] qui doivent être
#    enquêtés.
~~~

<a name="write-and-send-mail"></a>

**Rédiger et envoyer le mail de satisfaction**

On peut donc maintenant faire un mail de cette manière :

~~~ruby
sujet = "Éditions Icare — Enquête de satisfaction"
enquetes_requises_par_clients.each do |client, livres|
  
  mail   = client.mail
  titres = livres.collect { |p| p[:titre] }.pretty_join
  plusieurs = livres.count > 1
  s = plusieurs ? 's' : ''

  message = <<~TEXT
  Bonjour #{client.patronyme},
  
  Vous avez acheté récemment le#{s} livre#{s} : #{titres} et nous
  vous remercions encore de votre achat. Nous espérons que cette
  lecture vous a plu.
    
  Pour nous le dire, nous vous invitons à répondre à une
  enquête de satisfaction concernant ce#{s} livre#{s}. Vous la
  trouverez à l’adresse https://url/to/enquete
  
  En vous remerciant d’avance,
  
  Bien à vous,
  
  Les éditions Icare
    
	TEXT
  
  # On peut procéder à l'envoi (la méthode send_mail ci-dessous
  # est fictive
  send_mail(client.mail, sujet, MAIL_EDITIONS)
end
~~~

### Second moyen

Le second moyen consiste à relever tous les livres achetés il y a plus de 2 mois (et moins d’un an, comme précédemment) et, pour chacun d’eux, de voir si l’enquête de satisfaction a été envoyée à leur acheteur.

Le début se présente donc de la même manière :

**Relève des transactions sur les achats**

~~~ruby
require 'suivi'
require 'clir'

# Fichier principal
# @note
# 	On utilise '__dir__' car le script va être lancé depuis le
#   dossier contenant le fichier.
main_file = File.join(__dir__, 'clients_icare.csv')

# Le premier filtre
filtre_achats = {
  transaction: 'ACHAT', # Transaction de type 'ACHAT'
  before:Time.now - 60.days, # effectuée il y a 2 mois au moins
  after: Time.now - 365.days # pour accélérer les choses
}

# On relève les transactions
transactions_achats = Suivi::Transaction.find(main_file, filtre_achats)
# => Liste de toutes les instances Suivi::Transaction qui matchent
#    le filtre
~~~

Maintenant, on va boucler sur chaque livre pour savoir s’il a reçu l’enquête de satisfaction.

~~~ruby
transaction_enquetes = transactions_achats.reject do |transaction|
  # filtre pour rechercher la transaction d'enquête correspondante
  filtre_enquete = {
  	transaction: 'ENQUETE',
    client: 	transaction.client.id,
    produit: 	transaction.produit.id,
    only_one: true, # [1]
    after:    transaction.date # [2]
  }
  # On recherche la transaction
  resultat = Suivi::Transaction.find(main_file, filtre_enquete)
  # On rejette cette transaction si un résultat a été trouvé
  resultat.count > 0
end
~~~

> **\[1]** Pour accélérer, on interrompra la recherche sitôt un élément trouvé
>
> **\[2]** Forcément, cette enquête aura été envoyée après l’achat.

Comme précédemment, il suffit ensuite de [grouper par client](#group-by-client) pour [établir le mail et l’envoyer](#write-and-send-mail).

