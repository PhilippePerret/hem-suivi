require "test_helper"

class SuivisCSVTest < Minitest::Test

  def setup
    super
  end
  def teardown
  end

  # Sujet principal du test
  def file_de_suivis
    @file_de_suivi ||= file_avec_suivi.suivi
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

  # --- LES TESTS ---

  def test_repond_a_exist?
    assert_respond_to file_avec_suivi.suivi, :exist?
    assert(file_avec_suivi.suivi.exist?)
    refute(file_sans_suivi.suivi.exist?)
  end

  def test_retourne_la_bonne_liste
    res = file_de_suivis.load({cid: 1})
    expected = 2 # ajuster au besoin
    assert_equal(expected, res.count, "La liste de retour ne devrait comporter que #{expected} éléments")
    assert_instance_of Suivi::SuivisCSV::Row, res.first
    uliste = res.collect {|e| e.client_id }.uniq
    assert_equal(1, uliste.count, "Il ne devrait y avoir qu'un seul client concerné…")
  end

  def test_suivi_pour_un_produit_et_un_client
    # On veut obtenir le suivi du client #2 pour le produit #4
    res = file_de_suivis.load({cid:2, produit:4}, **{sort: :asc})
    # Noter qu'ici, pour le moment, ce sont les lignes CSV qui sont
    # retourner, donc pour tous les produits concernés à chaque
    # transaction.
    actual = res.collect { |row| row.transaction_id }
    expected = ['ACHAT','AVIS','REPONSE']
    assert_equal(expected, actual)
    res = file_de_suivis.load({cid:2, produit:4}, **{sort: :desc})
    actual = res.collect { |row| row.transaction_id }
    expected = ['REPONSE','AVIS','ACHAT']
    assert_equal(expected, actual)
  end

  def test_suivi_permet_de_obtenir_client_de_produit
    # On veut obtenir tous les clients d'un produit
    produit = Produit.get(1)

  end

end #/class Minitest
