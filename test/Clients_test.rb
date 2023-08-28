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
    # (il faut le faire maintenant pour que les dates soient valides)
    # 
    file_ok   = File.join(ASSETS_FOLDER,'files','good','ok.csv')
    good_prov = File.join(ASSETS_FOLDER,'files','good','prov.csv')
    FileUtils.copy(file_ok, good_prov)

    TestsUtils.build_suivi_file(good_prov, [
      {client:1, produits:'1+2',  transaction:'ACHAT', date:Time.now-80},
      {client:2, produits:'1',    transaction:'ACHAT',   date:Time.now-59}, # mauvaise date
      {client:3, produits:'1+3+5',transaction:'ACHAT', date:Time.now-70}, # achat sans enquête
      {client:1, produits:'1',    transaction:'ENQUETE', date: Time.now - 10}, # déjà enquête
    ])

    filtre  = {
      transaction: { id: 'ACHAT', before: (Time.now - 60) },
    }
    # TODO Il faudra faire aussi l'essai avec :
    #  transaction: { id: 'ACHAT', before: (Time.now - 60), produit: 1 },
    #     Qui signifie :  filtrer les transactions de type 'ACHAT', produites il y a plus
    #                     de deux mois, pour le produit 1
    #  transaction: { id: 'ACHAT', before: (Time.now - 60), client: 1 },

    # Doit retourner tous les clients qui ont acheté des livres
    # il y a plus de deux mois
    res = Suivi::Client.find(good_prov, **filtre)
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
      when 1 then 2
      when 2 then 1
      when 3 then 3
      end
      actual = data_client[:transactions].count
      assert_equal(nombre_transactions, actual, "Le client ##{client.id} devrait avoir #{nombre_transactions} transactions. Il en a #{actual}…")
      
      # - Produits -
      assert data_client.key?(:produits)
      assert_instance_of Array, data_client[:produits]
      premier_produit = data_client[:produits].first
      assert_instance_of Suivi::Produit, premier_produit
      nombre_produits = case client.id
      when 1 then 2
      when 2 then 1
      when 3 then 3
      end
      actual = data_client[:produits].count
      assert_equal(nombre_produits, actual, "Le client ##{client.id} devrait avoir #{nombre_produits} produits. Il en a #{actual}…")

      # - Pas de données clients -
      refute data_client.key?(:clients)

    end

    
  end
end #/class ClientSuiviTest
