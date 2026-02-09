package com.apweb.backend.repository;

import com.apweb.backend.model.CatalogoItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CatalogoItemRepository extends JpaRepository<CatalogoItem, Integer> {
}
