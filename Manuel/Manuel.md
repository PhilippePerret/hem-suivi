# 

# Filtre

Un filtre peut être simple ou composite. Simple, c'est une table (`Hash`). Par exemple :

~~~ruby
filtre_simple = {transaction: 'ACHAT', before: Time.now - 100.days}
~~~

Avec ce filtre, on cherche tous les achats remontant à plus de 100 jours. 

> Noter qu'en fonction de la méthode appelée, le résultat sera présenté sous différentes formes.

Un filtre composite comprendre plusieurs filtres simples à la suite, qui doivent tous passer.

~~~ruby
filtre_composite = [
  {transaction: 'ACHAT', before:Time.now - 100.days},
  
]
~~~




Attention aux mauvais filtres. Par exemple :

~~~ruby
filtre = [
    {transaction: 'ACHAT, before: Time.now - 100.days},
    {transaction: 'ENQUETE', before: Time.now - 100.days}
  ]
~~~

Le filtre ci-dessus renverra forcément une liste vide puisque le premier filtre relèvera les transactions de type 'ACHAT' puis recherchera dans ces transactions de type 'ACHAT' les transactions de type 'ENQUETE'. Il n'y en aura bien sûr aucune.

Il convient de faire :

~~~ruby
filtre = {transaction: ['ACHAT','ENQUETE'], before: Time.now - 100.days}
~~~

Si les dates doivent être différentes pour les deux types, alors il convient de faire deux recherches :

~~~ruby
filtre_achat = {transaction: 'ACHAT', before: Time.now - 100.days}
transactions_achat = Suivi::Transaction.find(main_file, filtre_achat)

filtre_enquete = {transaction:'ENQUETE', before: Time.now - 20.days}
transactions_enquete = Suivi::Transaction.find(main_file, filtre_enquete)

# Croiser les deux résultats pour obtenir la liste voulue.
~~~
