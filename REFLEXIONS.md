# Réflexions

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
Suivi::Client.find(filter, options)
~~~

Le premier argument va définir le filtre à appliquer à la recherche. On cherche, parmi les suivis, les transactions qui concernent un ou des achats. L'identifiant de cette transaction est 'ACHAT'. Donc :

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
resultats = Suivi::Client.find(filtre)

~~~

… retournera donc une liste contenant tous les clients concernés :

~~~
resultats = [
  {client: <instance du client>, produits: [<liste des livres (instances Produit)>]}
]
~~~

Pour produire la liste des destintaires (pour `Mailing` par exemple), il suffira donc de faire :

~~~
filtre = {
  transaction: { id: 'ACHAT', before: (Time.now - 60) },
  produit: { not_transaction: 'ENQUETE' }
}
Suivi::Client.find(filtre).collect do |hdata|
  client = hdata[:client]
  Receiver.get(client.id).variables.merge!({
    titres: hdata[:produits].collect { |p| p.titre }.pretty_join 
  })
end
~~~
