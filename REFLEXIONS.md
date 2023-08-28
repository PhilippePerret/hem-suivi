# Réflexions

Principes finaux :

* on ne fait pas de filtres complexes. Un filtre sert seulement à relever des transactions qui correspondent à une recherche simple sur des produits, des transactions, des clients. Ensuite, on récupère cette liste pour choisir vraiment ce qu'on veut.

* Toutes les méthodes de classe `find` retournent une table avec :
  * en clé l'instance de l'objet de la classe (par exemple un Suivi::Client si c'est Suivi::Client::find qui est utilisé)
  * en valeur une table contenant :
    * :transactions, la liste des transactions concernant le client
    * :produits, sauf si c'est `Suivi::Produit::find` qui a été utilisé, la liste des produits concernant le client ou la transaction
    * :clients, sauf si c'est `Suivi::Client::find` qui a été appelé, la liste des clients concernant la transaction ou le produit

Par exemple, pour l'opération qui a entrainé ce gem :
On doit faire un mailing à tous les gens qui ont acheté un livre il y a plus de 2 mois et qui n'ont pas encore reçu l'enquête de satisfaction. L'appel à `Suivi` doit retourner la liste destinataire, avec les livres qu'ils ont achetés et pour lesquels on veut leur avis.

Synopsis
- Dans un premier temps, on relève toutes les transactions d'achat en les classant par client. Donc on utilise :

  ~~~ruby
    filtre = {transaction: {id: 'ACHAT', before: Time.now - 60}}
    resultats = Suivi::Client.find(filtre, path_to_main_file)
  ~~~

  `resultats` sera une table qui contiendra en clé le client et en valeur une table avec ses suivis et notamment ses `produits` donc ses livres achetés.

  On bouclera sur ces produits/livres pour connaitre ceux qui n'ont pas eux d'enquête. Donc :

  ~~~ruby
  resultats.each do |client, data_client|
    data_client.merge!(livres: {} )
    data_client[:produits].each do |produit|
        if produit.has_transaction?('ENQUETE') 
          NOTE : POUR AVOIR ÇA (CI-DESSUS), IL FAUDRAIT, DANS LA BOUCLE QUI RAMASSE LES DONNÉES,
          METTRE TOUTES LES TRANSACTIONS PROPRES À UN PRODUIT DANS CE PRODUIT (SI ÇA N'EST PAS
          DÉJÀ FAIT)
          data_client[:livres].delete(:produit)
        end
    end
  end
  ~~~


Ce gem a été pensé au départ pour gérer les transactions auprès des clients de la maison d'éditions Icare. Principalement pour faire un suivi rigoureux auprès des lecteurs.

# Étude de cas

On veut faire un mailing à des clients qui ont acheté un ou plusieurs livres dans les 2 mois qui précèdent (ou plus la première fois) pour leur envoyer une enquête de satisfaction.
Ce mailing étant envoyé régulièrement, par exemple, tous les 15 jours, il ne faut pas l'envoyer deux fois.

Donc, on doit relever les clients (objets du mailing) qui ont fait un achat (transaction) plus de 2 mois auparavant, pour acheter un ou plusieurs livres (produit) mais qui n'ont pas, pour ces livres-là, reçu de questionnaire de satisfaction.

Donc, puisqu'on veut des clients, on va utiliser la classe :

~~~
Suivi::Client
~~~

… et sa méthode `find` puisqu'on veut trouver ces clients.

~~~
Suivi::Client.find(file, filter, options)
~~~

Le premier argument définit le chemin d'accès au fichier CSV qui définit les clients. Sans autre précision, un fichier suivi naturel (de nom `<affixe>_suivi.csv`) doit exister et contenir le suivi. Ce fichier de suivi définira le chemin d'accès aux transactions et aux produits.

Le second argument va définir le filtre à appliquer à la recherche. On cherche, parmi les suivis, les transactions qui concernent un ou des achats. L'identifiant de cette transaction est 'ACHAT'. Donc :

~~~
filter = {transaction: 'ACHAT'}
~~~

Mais on veut que ces achats aient été faits il y a deux mois ou plus. C'est donc une recherche plus complexe :

~~~
filter = {transaction: {id: 'ACHAT', before: (Time.now - 60)}}
~~~

Ce filtre, pour le moment, va retourner tous les achats faits il y a plus de deux mois auparavant. Mais nous voulons seulement les livres (produit) pour lesquels il n'y a pas eu d'enquête de satisfaction. Nous devons donc ajouter :

~~~
filtre = {
  transaction: { id: 'ACHAT', before: (Time.now - 60) },
  not_transaction: 'ENQUETE'
}
~~~

Question : mais comment savoir, ici, que c'est sur le produit qu'il faudra faire la recherche de la `not_transaction` ? Ici, on ne peut pas le faire. Donc il faut utiliser plutôt :

~~~
filtre = {
  transaction: { id: 'ACHAT', before: (Time.now - 60) },
  produit: { not_transaction: 'ENQUETE' }
}
~~~

Cette deuxième ligne signifie : pour les produits (livres) trouvés, ne prendre que ceux qui n'ont pas reçu d'enquête de satisfaction.

Le second argument de la méthode `Suivi::Client.find` permet de définir un peu mieux le retour. Ici, on veut grouper par client, donc on pourrait vouloir utiliser `options = {group_by: :client}` mais c'est inutile puisque la méthode `Client.find` le fait naturellement.

Le résultat du code suivi :

~~~
filtre = {
  transaction: { id: 'ACHAT', before: (Time.now - 60) },
  produit: { not_transaction: 'ENQUETE' }
}
file = /path/to/clients.csv
resultats = Suivi::Client.find(file, filtre)

~~~

… retournera donc une liste contenant tous les clients concernés :

~~~
resultats = [
  {client: <instance du client>, produits: [<liste des livres (instances Produit)>]}
]
~~~

Pour produire la liste des destintaires (pour `Mailing` par exemple), il suffira donc de faire :

~~~
file = '/path/to/clients.csv'
filtre = {
  transaction: { id: 'ACHAT', before: (Time.now - 60) },
  produit: { not_transaction: 'ENQUETE' }
}
Suivi::Client.find(file, filtre).collect do |hdata|
  client = hdata[:client] # Instance Suivi::Client
  # On définit les variables qui vont être utiles pour le mailing
  Receiver.get(client.id).variables.merge!({
    titres: hdata[:produits].collect { |p| p.titre }.pretty_join 
  })
end
~~~
