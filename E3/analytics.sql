---------------------------------------------
--OLAP
---------------------------------------------

-- 1.
SELECT dia_semana, concelho, SUM(unidades) 
FROM vendas 
WHERE (ano > 2022 OR (ano = 2022  AND ( mes > 5 OR  ( mes=5 AND (dia_mes >= 21))))) 
AND (ano < 2023 OR (ano = 2023 AND (mes < 2 OR (mes = 2 AND (dia_mes <= 18))))) 
GROUP BY CUBE(dia_semana,concelho) ORDER BY(dia_semana,concelho);

-- 2.
SELECT concelho, cat, dia_semana, SUM(unidades)
FROM vendas
WHERE distrito = 'Lisboa'
GROUP BY GROUPING SETS((concelho), (cat), (dia_semana), ())
ORDER BY(concelho, cat, dia_semana);
