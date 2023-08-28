require 'test_helper'

class SuiviFileTest < Minitest::Test

  def setup
    super
    
  end

  def file_avec_suivi
    @file_avec_suivi ||= Suivi::File.new(path_avec_suivi)
  end
  def path_avec_suivi
    @path_avec_suivi ||= File.join(ASSETS_FOLDER,'files','good','ok.csv')
  end

  def file_sans_suivi
    @file_sans_suivi ||= Suivi::File.new(path_sans_suivi)
  end
  def path_sans_suivi
    @path_sans_suivi ||= File.join(ASSETS_FOLDER,'files','bad','sans_suivi.csv')
  end


  # --- TESTS MÉTHODES PRINCIPALES ---


  def test_obtain_suivi_for_client_and_produit
    main_file = File.join(ASSETS_FOLDER,'files','good', 'ok.csv')
    #
    # Méthode pour obtenir le suivi complet pour un client et un
    # produit particulier
    # 
    res = file_avec_suivi.find_suivis({client: 2, produit: 4, **{as: :transaction}})
    # res doit contenir une liste de 3 transactions pour le produit 4
    assert_equal 3, res.count, "La liste devrait contenir 3 transactions"
    assert_instance_of Suivi::Transaction, res.first, "Le premier élément devrait être une instance Suivi::Transaction"
    res.each do |row|
      assert_equal Suivi::Produit.get(main_file, 4), row.produit, "Le produit de la transaction devrait être le #4. Or c'est le #{tran.produit.id}"
    end
    assert_equal 'ACHAT',   res[0].transaction_id, "La première transaction devrait être un ACHAT"
    assert_equal 'ENQUETE', res[1].transaction_id, "La deuxième transaction devrait être une demande d'AVIS"
    assert_equal 'REPONSE', res[2].transaction_id, "La troisième transaction devrait être une RÉPONSE"

  end

  def test_obtain_produits_filtred_by_transaction
    #
    # Test de la méthode pour obtenir des produits qui contiennent 
    # une certaine transaction mais n'en contiennent pas une autre,
    # et qui ont été achetés avant une certaine date mais pas avant
    # une autre, pour tous les clients
    # 
    main_file = File.join(ASSETS_FOLDER,'files','good', 'ok.csv')
    filter = {
      transaction:      {id: 'ACHAT', before: '2023-07-01', not_before: '2022-01-01'}, 
      not_transaction:  'ENQUETE',
    }
    res = Suivi::Produit.find(main_file, filter)
    # Il n'y en a qu'une
    assert_equal 1, res.count, "Il ne devrait y avoir qu'un seul produit"
    assert_equal 2, res.first.produit.id, "Le produit concerné devrait être le produit #2"
  end

  def test_obtain_suivis_for_client
    #
    # Méthode pour obtenir le suivi complet pour un client
    # 

  end




  # --- TESTS MÉTHODES SECONDAIRES ---

  def test_class_suivi_file_existe
    assert defined?(Suivi::File), "La classe Suivi::File devrait exister"
  end

  def test_on_peut_initier_un_fichier_existant
    assert_silent { Suivi::File.new(path_avec_suivi)}
  end

  def test_on_ne_peut_initier_un_fichier_inexistant
    pth = '/bad/path/to_file.csv'
    err = assert_raises { Suivi::File.new(pth)}
    assert_equal(ERRORS[:file][:unknown_path] % pth, err.message)
  end
  def test_on_ne_peut_initier_un_fichier_autre_que_csv
    pth = File.join(ASSETS_FOLDER,'files','bad','mauvais.ext')
    err = assert_raises { Suivi::File.new(pth)}
    assert_equal(ERRORS[:file][:bad_extension] % pth, err.message)
  end
  def test_on_ne_peut_initier_un_fichier_sans_id
    pth = File.join(ASSETS_FOLDER,'files','bad','sans_id.csv')
    err = assert_raises { Suivi::File.new(pth) }
    assert_equal(ERRORS[:file][:key_id_required] % pth, err.message)
  end

  def test_repond_a_has_suivi
    assert_respond_to file_avec_suivi, :has_suivi?, "un fichier devrait répondre à has_suivi?"
    assert(file_avec_suivi.has_suivi?)
    refute(file_sans_suivi.has_suivi?)
  end

  def test_file_as_property_suivi_de_class_suivi_doc
    assert_respond_to file_avec_suivi, :suivi
    assert_respond_to file_sans_suivi, :suivi
    assert_equal(Suivi::SuivisCSV, file_avec_suivi.suivi.class, "Le fichier de suivi devrait être de class Suivi::SuivisCSV")
    assert_equal(Suivi::SuivisCSV,file_sans_suivi.suivi.class, "Le fichier de suivi devrait être de class Suivi::SuivisCSV")
  end



end #/class Minitest
