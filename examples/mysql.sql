drop table if exists products;
drop table if exists product_types;
drop table if exists manufacturers;

CREATE TABLE manufacturers (
    id integer not null AUTO_INCREMENT,
    name text not null,
    man_id integer CHECK (man_id > 0),
    primary key(id),
    UNIQUE(man_id)
);

CREATE TABLE product_types (
    id integer AUTO_INCREMENT primary key,
    name text not null,
    description text,
    manufacturer integer not null references manufacturers(id)
);

CREATE TABLE products (
    id integer AUTO_INCREMENT primary key,
    name text not null,
    price numeric CHECK (price > 0),
    product_type_id integer references product_types(id)
);

create index products_product_type_id_index on products(product_type_id);

insert into manufacturers (name, man_id) values ('type a', 666);
insert into product_types (name, description) values ('type a', 'An A type of thing');
insert into products (name, price, product_type_id) values ('product a', 10.00, 1);

select * from sqlite_master;

