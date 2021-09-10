library(magrittr, include.only = "%>%")

#' Gerar tabela com países e respectivas capitais
#'
#' @param caminho Caminho onde será salva a base de dados no seu computador.
#'
#' @return Retorna uma tibble com a tabela com os países, capitais e continentes.
#' @export
#'
#' @examples
gerar_tabela <- function(caminho) {

paises_america <- httr::GET("https://brasilescola.uol.com.br/geografia/paises-america.htm")
paises_africa <- httr::GET("https://brasilescola.uol.com.br/geografia/paises-da-africa.htm")
paises_europa <- httr::GET("https://pt.wikipedia.org/wiki/Europa")
paises_oceania <- httr::GET("https://pt.wikipedia.org/wiki/Oceania")
paises_asia <- httr::GET("https://www.sport-histoire.fr/pt/Geografia/Paises_Asia.php")

america <- paises_america %>%
  httr::content() %>%
  rvest::html_table(header = TRUE) %>%
  purrr::pluck(1) %>%
  janitor::clean_names()

africa <- paises_africa %>%
  httr::content() %>%
  rvest::html_table() %>%
  purrr::pluck(1) %>%
  tidyr::unite(col = "pais") %>%
  tidyr::separate_rows(pais, sep = "[_]") %>%
  dplyr::mutate(capital = stringr::str_extract(pais, "\\(.*?\\)"),
    capital = stringr::str_remove_all(capital, "\\(|\\)"),
    pais = stringr::str_squish(stringr::str_remove_all(pais, "\\(.*.")),
    continente = "África")

europa <- paises_europa %>%
  httr::content() %>%
  rvest::html_table() %>%
  purrr::pluck(6) %>%
  purrr::set_names(c("pais", "area", "pop", "dens_pop", "capital")) %>%
  dplyr::select(pais, capital) %>%
  dplyr::mutate(continente = "Europa")

oceania <- paises_oceania %>%
  httr::content() %>%
  rvest::html_table() %>%
  purrr::pluck(5) %>%
  dplyr::select(1, 5) %>%
  dplyr::slice(-1, -7, -15, -23, -34) %>%
  purrr::set_names("pais", "capital") %>%
  dplyr::mutate(pais = stringr::str_squish(stringr::str_remove_all(pais, "\\(.*.")),
    capital = ifelse(capital == "não possui capital", NA, capital),
    continente = "Oceania")

asia <- paises_asia %>%
  httr::content() %>%
  rvest::html_table() %>%
  purrr::pluck(1) %>%
  purrr::set_names("pais", "capital", "dropar") %>%
  dplyr::select(-dropar) %>%
  dplyr::filter(!stringr::str_detect(pais, "google")) %>%
  dplyr::mutate(continente = "Ásia")

continentes <- dplyr::bind_rows(america, africa, asia, europa, oceania)

return(continentes)

}
