CREATE OR REPLACE VIEW vendas AS
SELECT ean,
    prat.nome AS cat, 
    EXTRACT(YEAR FROM instante) AS ano, 
    EXTRACT(QUARTER FROM instante) AS trimestre, 
    EXTRACT(MONTH FROM instante) AS mes,
    EXTRACT(DAY FROM instante) AS dia_mes, 
    CASE EXTRACT(DOW FROM instante)
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Segunda'
        WHEN 2 THEN 'Terça'
        WHEN 3 THEN 'Quarta'
        WHEN 4 THEN 'Quinta'
        WHEN 5 THEN 'Sexta'
        WHEN 6 THEN 'Sábado'
    END AS dia_semana, 
    distrito, 
    concelho, 
    unidades_evento AS unidades 
    FROM prateleira AS prat NATURAL JOIN evento_reposicao
        NATURAL JOIN instalada_em  
        JOIN ponto_de_retalho ON local_ = ponto_de_retalho.nome;