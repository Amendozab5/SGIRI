package com.apweb.backend.config;

import org.springframework.beans.BeansException;
import org.springframework.beans.factory.config.BeanPostProcessor;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;

@Component
public class DataSourcePostProcessor implements BeanPostProcessor {
    @Override
    public Object postProcessAfterInitialization(@org.springframework.lang.NonNull Object bean,
            @org.springframework.lang.NonNull String beanName) throws BeansException {
        if (bean instanceof DataSource && !(bean instanceof RoleSettingDataSource)) {
            // Unicamente lo envolvemos si no ha sido envuelto por RoleSettingDataSource.
            // A veces Spring Boot envuelve DataSources con proxy para transacciones.
            return new RoleSettingDataSource((DataSource) bean);
        }
        return bean;
    }
}
