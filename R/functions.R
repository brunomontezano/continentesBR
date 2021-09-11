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
  pop_paises <- httr::GET("https://pt.wikipedia.org/wiki/Lista_de_pa%C3%ADses_por_popula%C3%A7%C3%A3o")
  area_paises <- httr::GET("https://pt.wikipedia.org/wiki/Lista_de_pa%C3%ADses_e_territ%C3%B3rios_por_%C3%A1rea")

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

  # Raspagem e limpeza dos dados de populacao dos paises
  pop <- pop_paises %>%
    httr::content() %>%
    rvest::html_table() %>%
    purrr::pluck(1) %>%
    janitor::clean_names() %>%
    dplyr::rename(
      posicao_pop = posicao,
      pop = estimativa_da_onu,
      data_pop = data,
      pais = pais_ou_territorio_dependente
    ) %>%
    dplyr::select(-estimativa_oficial)

  # Raspagem e limpeza dos dados de area dos paises
  area <- area_paises %>%
    httr::content() %>%
    rvest::html_table() %>%
    utils::head(6) %>%
    purrr::map(
      function(x) {
        dplyr::mutate(x, Ordem = as.character(Ordem))
      }
    ) %>%
    purrr::map(
      function(x) {
        purrr::set_names(x, nm = c("ordem", "pais", "area_km2", "obs"))
      }
    ) %>%
    dplyr::bind_rows() %>%
    dplyr::rename(
      posicao_area = ordem
    ) %>%
    dplyr::select(-obs)

  # Adicionar populacao e area na base e calcular densidade populacional
  continentes_proc <- continentes %>%
    dplyr::left_join(pop, by = "pais") %>%
    dplyr::left_join(area, by = "pais") %>%
    dplyr::mutate(
      dplyr::across(
        c(pop, area_km2),
        ~ readr::parse_number(stringr::str_remove_all(.x, "[:blank:]"))
      )) %>%
    dplyr::mutate(
      dens_pop = pop / area_km2
    ) %>%
    dplyr::mutate(
      dplyr::across(c(posicao_pop, posicao_area),
        ~ readr::parse_integer(
          stringr::str_replace_all(.x, "[^[0-9]]", "")
        ))
    )

  # Criar a condicional para o parametro de salvar e formato
  if (salvar == TRUE & formato == "csv") {

    readr::write_csv(continentes_proc, file = "tabela_continentes.csv")

  } else if (salvar == TRUE & formato == "excel") {

    writexl::write_xlsx(continentes_proc, path = "tabela_continentes.xlsx")

  } else if (salvar == TRUE & !(formato %in% c("csv", "excel"))) {

    stop("Formato possivelmente errado.")

  }

  # Retornar objeto da tibble ao final da function
  return(continentes_proc)

}
