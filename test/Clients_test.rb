require 'test_helper'

class ClientSuiviTest < Minitest::Test

  def setup
    super
  end

  def test_class_client_existe
    assert defined?(Suivi::Client), "La classe Suivi::Client devrait exister"
  end

  def test_instance_client_repond_a_find
    assert_respond_to Suivi::Client, :find
  end

  # 
  def test_method_find_renvoie_bons_resultats
    # 
    # Faire le fichier principal provisoire
    # 
    file_ok   = File.join(ASSETS_FOLDER,'files','good','ok.csv')
    good_prov = File.join(ASSETS_FOLDER,'files','good','prov.csv')
    FileUtils.copy(file_ok, good_prov)

    TestsUtils.build_suivi_file(good_prov, [
      {client:1, produits:'1+2',  transaction:'ACHAT', date:Time.now-80},
      {client:2, produits:'1',    transaction:'ACHAT',   date:Time.now-59}, # mauvaise date
      {client:3, produits:'1+5',  transaction:'ACHAT', date:Time.now-70}, # achat sans enquête
      {client:1, produits:'1',    transaction:'ENQUETE', date: Time.now - 10}, # déjà enquête
    ])

    filtre  = {
      transaction: { id: 'ACHAT', before: (Time.now - 60) },
    }
    # NON, en fait, pour faire ça, il faut fonctionner en deux temps :
    # 1. On récupère tous les achats fait deux mois plus tôt, par
    #    produit, donc avec Suivi::Produit.find()
    # 2. Ensuite, dans les produits retournés, on choisit seulement
    #    ceux qui n'ont pas reçu d'enquête de satisfaction
    # BINGO !

    # Doit retourner tous les clients qui ont acheté des livres
    # il y a plus de deux mois
    res = Suivi::Client.find(good_prov, **filtre)
    # Ce premier retour
    assert_instance_of Hash, res
    res.each do |client, data_client|

      assert_instance_of Suivi::Client, client
      assert_instance_of Hash, data_client

      # - Rangées -
      assert data_client.key?(:rows)
      assert_instance_of Array, data_client[:rows]
      premiere_rangee = data_client[:rows].first
      assert_instance_of Suivi::SuivisCSV::Row, premiere_rangee
      
      # - Transactions -
      assert data_client.key?(:transactions)
      assert_instance_of Array, data_client[:transactions]
      premiere_transaction = data_client[:transactions].first
      assert_instance_of Suivi::Transaction, premiere_transaction
      nombre_transactions = case client.id
      when 1 then 3
      when 2 then 1
      when 3 then 2
      end
      actual = data_client[:transactions].count
      assert_equal(nombre_transactions, actual, "Le client ##{client.id} devrait avoir #{nombre_transactions} transactions. Il en a #{actual}…")
      
      # - Produits -
      assert data_client.key?(:produits)
      assert_instance_of Array, data_client[:produits]
      premier_produit = data_client[:produits].first
      assert_instance_of Suivi::Produit, premier_produit

      # - Pas de données clients -
      refute data_client.key?(:clients)

    end

    
  end
end #/class ClientSuiviTest
