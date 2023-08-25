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
    assert_equal(Suivi::SuiviCSV, file_avec_suivi.suivi.class, "Le fichier de suivi devrait être de class Suivi::SuiviCSV")
    assert_equal(Suivi::SuiviCSV,file_sans_suivi.suivi.class, "Le fichier de suivi devrait être de class Suivi::SuiviCSV")
  end



end #/class Minitest
