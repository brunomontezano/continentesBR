test_that("Função gerar_tabela() retorna uma tibble", {
  library(magrittr)
  tabela <- gerar_tabela()

  testthat::expect_equal(class(tabela), c("tbl_df", "tbl", "data.frame"))
})
