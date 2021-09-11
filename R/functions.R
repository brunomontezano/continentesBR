#' Gera uma tabela com países, capitais e continentes do mundo
#'
#'
#' @param salvar Decidir se deve ser salvo um arquivo local no computador com a tabela. Valor padrão: `FALSE`
#' @param formato Formato do arquivo a ser salvo localmente. Por padrão, "csv". Valores disponíveis: "csv" e "xlsx".
#'
#' @return Retorna uma tibble contendo países, capitais e seus respectivos continentes.
#' @export
#'
gerar_tabela <- function(salvar = FALSE, formato = "csv") {

  # Juntar URLs para cada um dos sites a serem raspados
  paises_america <- httr::GET("https://brasilescola.uol.com.br/geografia/paises-america.htm")
  paises_africa <- httr::GET("https://brasilescola.uol.com.br/geografia/paises-da-africa.htm")
  paises_europa <- httr::GET("https://pt.wikipedia.org/wiki/Europa")
  paises_oceania <- httr::GET("https://pt.wikipedia.org/wiki/Oceania")
  paises_asia <- httr::GET("https://www.sport-histoire.fr/pt/Geografia/Paises_Asia.php")

  # Puxar e limpar base da America
  america <- paises_america %>%
    httr::content() %>%
    rvest::html_table(header = TRUE) %>%
    purrr::pluck(1) %>%
    janitor::clean_names()

  # Puxar e limpar base da Africa
  africa <- paises_africa %>%
    httr::content() %>%
    rvest::html_table() %>%
    purrr::pluck(1) %>%
    tidyr::unite(col = "pais") %>%
    tidyr::separate_rows(pais, sep = "[_]") %>%
    dplyr::mutate(capital = stringr::str_extract(pais, "\\(.*?\\)"),
      capital = stringr::str_remove_all(capital, "\\(|\\)"),
      pais = stringr::str_squish(stringr::str_remove_all(pais, "\\(.*.")),
      continente = "\u00c1frica")

  # Puxar e limpar base da Europa
  europa <- paises_europa %>%
    httr::content() %>%
    rvest::html_table() %>%
    purrr::pluck(6) %>%
    purrr::set_names(c("pais", "area", "pop", "dens_pop", "capital")) %>%
    dplyr::select(pais, capital) %>%
    dplyr::mutate(continente = "Europa")

  # Puxar e limpar base da Oceania
  oceania <- paises_oceania %>%
    httr::content() %>%
    rvest::html_table() %>%
    purrr::pluck(5) %>%
    dplyr::select(1, 5) %>%
    dplyr::slice(-1, -7, -15, -23, -34) %>%
    purrr::set_names("pais", "capital") %>%
    dplyr::mutate(pais = stringr::str_squish(stringr::str_remove_all(pais, "\\(.*.")),
      capital = ifelse(capital == "n\u00e3o possui capital", NA, capital),
      continente = "Oceania")

  # Puxar e limpar base da Asia
  asia <- paises_asia %>%
    httr::content() %>%
    rvest::html_table() %>%
    purrr::pluck(1) %>%
    purrr::set_names("pais", "capital", "dropar") %>%
    dplyr::select(-dropar) %>%
    dplyr::filter(!stringr::str_detect(pais, "google")) %>%
    dplyr::mutate(continente = "\u00c1sia")

  # Criar base de dados unica com todos os continentes
  continentes <- dplyr::bind_rows(america, africa, asia, europa, oceania)

  # Criar a condicional para o parametro de salvar e formato
  if (salvar == TRUE & formato == "csv") {

    readr::write_csv(continentes, file = "tabela_continentes.csv")

  } else if (salvar == TRUE & formato == "excel") {

    writexl::write_xlsx(continentes, path = "tabela_continentes.xlsx")

  } else if (salvar == TRUE & !(formato %in% c("csv", "excel"))) {

    stop("Formato possivelmente errado.")

  }

  # Retornar objeto da tibble ao final da function
  return(continentes)

}
