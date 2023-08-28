La méthode centrale pour récupérer des transactions est **Suivi::File#find_suivis** :

~~~ruby
Suivi::File#find_suivis(filtre, options)
~~~

Donc, quand on a un chemin d'accès à un fichier de "clients". On fait :

~~~ruby
main_file = Suivi::File.new("/path/to/file/clients.csv")
filtre = ...
options = ...
transaction = main_file.find_suivis(filtre, options)
~~~
