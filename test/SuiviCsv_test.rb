require "test_helper"

class SuiviCSVTest < Minitest::Test

  def setup
    super
  end
  def teardown
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
    res = file_avec_suivi.suivi.load(cid: 1)
    expected = 2 # ajuster au besoin
    assert_equal(expected, res.count, "La liste de retour ne devrait comporter que #{expected} éléments")
    uliste = res.collect {|e| e['Cid'] }.uniq
    assert_equal(1, uliste.count, "Il ne devrait y avoir qu'un seul client concerné…")
  end


end #/class Minitest
