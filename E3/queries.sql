--- 1.

SELECT name_ 
FROM retalhista NATURAL JOIN responsavel_por 
GROUP BY tin
HAVING COUNT(nome_cat) >= ALL(
SELECT COUNT(nome_cat) 
FROM retalhista NATURAL JOIN responsavel_por
GROUP BY tin);

--- 2.

SELECT DISTINCT name_
FROM retalhista 
WHERE NOT EXISTS (
SELECT nome
FROM categoria_simples 
EXCEPT
SELECT nome_cat
FROM (responsavel_por JOIN retalhista
ON responsavel_por.tin = retalhista.tin) AS RR
WHERE RR.name_ = retalhista.name_);

---3.

SELECT ean 
FROM produto 
WHERE ean NOT IN (SELECT ean FROM evento_reposicao);

--- 4.

SELECT ean 
FROM (SELECT DISTINCT ean, tin FROM evento_reposicao) AS count_ean
GROUP BY ean 
HAVING COUNT(ean) = 1;