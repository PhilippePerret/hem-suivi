#
# Ce test est un cas grandeur nature qui simule une situation
# réelle à résoudre (celle qui est à la base de la fabrication de
# ce gem) :
# 
# Soit une maison d'éditions qui vend des livres.
# On a un fichier principal qui est le fichier des clients, c'est-à-
# dire des personnes qui ont acheté un ou plusieurs livres, en une
# ou plusieurs fois.
# 
# On doit faire une ENQUÊTE DE SATISFACTION. Cette enquête doit être
# effectuée deux mois après l'achat (la vérification est faite touts
# les 15 jours).
# 
# Donc, tous les 15 jours, il faut vérifier dans le suivi les livres
# qui ont été achetés plus de 15 jours auparavant et qui n'ont pas
# reçu d'enquête de satisfaction.
# 
# Pour accélérer la manœuvre, on peut passer les livres qui ont été
# acheté il y a plus d'un an.
# 
require 'test_helper'
class ComplexeFindTransactionsTest < Minitest::Test

  def setup
    super
  end

  # Test sur un fichier simple
  def test_method_find_renvoie_bons_resultats
    # 
    # Faire le fichier suivi provisoire
    # (il faut le faire maintenant pour que les dates soient valides)
    #
    prepare_fichier_suivi

    # Filtre qui permet de relever les transactions d'achat qui ont
    # eu lieu il y a au moins 2 mois et moins vieille qu'un an à 
    # peu près
    filtre_achats  = {
      transaction: 'ACHAT',
      after: (Time.now - 365.days),
      before: (Time.now - 60.days)
    }
    transactions_achat = Suivi::Transaction.find(main_file_prov, filtre_achats)

    # --- Vérifications ---
    expected = 6
    actual   = transactions_achat.count
    assert_equal(expected, actual, "Il devrait y avoir #{expected} transactions d'achat. Il y en a #{actual}.")

    # Filtre qui permet de relever toutes les transactions enquête
    # qui ont eu lieu dans l'année
    # 
    filtre_enquetes = {
      transaction: 'ENQUETE',
      after: Time.now - 365.days
    }
    transactions_enquete = Suivi::Transaction.find(main_file_prov, filtre_enquetes)

    # --- Vérifications ---
    expected = 3
    actual = transactions_enquete.count
    assert_equal(expected, actual, "Il devrait y avoir #{expected} enquêtes. Il y en a eu #{actual}.")

    # Maintenant on recoupe les deux informations pour obtenir la
    # liste des livres qui n'ont pas reçu d'enquête pour un client
    # donné

    # On commence par faire une table qui contiendra en clé l'id
    # du client et en valeur sa liste de livres enquêtées
    livres_enqueted_de = {}
    transactions_enquete.each do |trans|
      unless livres_enqueted_de.key?(trans.client_id)
        livres_enqueted_de.merge!(trans.client_id => [])
      end
      livres_enqueted_de[trans.client_id] << trans.produit_id
    end
    # TODO (on pourrait vérifier la table livres_enqueted_de)

    # On retire les livres enquêtés
    enquetes_a_faire = transactions_achat.reject do |trans|
      livre   = trans.produit_id
      client  = trans.client_id
      livres_enqueted_de[client].include?(livre)
    end

    # On regroupe par client
    enquetes_par_client = {}
    enquetes_a_faire.each do |trans|
      unless enquetes_par_client.key?(trans.client.id)
        enquetes_par_client.merge!(trans.client.id => [])
      end
      enquetes_par_client[trans.client.id] << trans.produit.id
    end

    # Livres par clients
    expected = {1 => [2], 3 => [1,5]}
    assert_equal(expected, enquetes_par_client)

    # tout est ok si on arrive ici
  end


  # 
  # Pour préparer le fichier des suivis qui va permettre de 
  # générer des résultats
  # 
  def prepare_fichier_suivi
    file_ok   = File.join(ASSETS_FOLDER,'files','good','ok.csv')
    FileUtils.copy(file_ok, main_file_prov)

    now = Time.now

    TestsUtils.build_suivi_file(main_file_prov, [
      {client:2, produits:'5',    transaction:'ACHAT',    date:now - 699.days}, # trop vieux
      {client:2, produits:'5',    transaction:'ENQUETE',  date:now - 658.days}, # trop vieux
      {client:1, produits:'5',    transaction:'ACHAT',    date:now - 400.days}, # trop vieux pour être enquêté
      {client:1, produits:'1+2',  transaction:'ACHAT',    date:now - 80.days},
      {client:3, produits:'1+3+5',transaction:'ACHAT',    date:now - 70.days}, # achat sans enquête
      {client:4, produits:'4',    transaction:'ACHAT',    date:now - 65.days}, # achat + enquête
      {client:2, produits:'1',    transaction:'ACHAT',    date:now - 52.days}, # trop récent
      {client:1, produits:'1',    transaction:'ENQUETE',  date:now - 10.days}, # déjà enquêté
      {client:3, produits:'3',    transaction:'ENQUETE',  date:now - 20.days}, # déjà enquêté
      {client:4, produits:'4',    transaction:'ENQUETE',  date:now - 15.days},
      {client:5, produits:'1+2+3',transaction:'ACHAT',    date:now - 15.days}, # achat trop récent
    ])    
  end

  def main_file_prov
    @main_file_prov ||= File.join(ASSETS_FOLDER,'files','good','prov.csv').freeze
  end

end #/class ClientSuiviTest
