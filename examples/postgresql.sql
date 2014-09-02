drop view if exists all_data;
drop table if exists products cascade;
drop table if exists product_types cascade;
drop table if exists manufacturers cascade;
drop table if exists album cascade;
drop table if exists song cascade;
-- drop trigger if exists song_check_songname ;

CREATE TABLE manufacturers (
    "id" serial PRIMARY KEY,
    "name" text not null,
    man_id integer UNIQUE,
    "UNIQUE" integer DEFAULT 123,
    """an """"id""" integer UNIQUE,
    notes varchar(50) not null default 'this is a test note',
    CHECK (man_id > 0)
);

CREATE TABLE product_types (
    "id" serial PRIMARY KEY,
    "name" text not null,
    description text,
    manufacturer_id integer references manufacturers(id) on delete SET NULL on update CASCADE
);

CREATE TABLE products (
    "id" INTEGER,
    "name" text not null UNIQUE,
    price numeric CHECK (price > 0),
    product_type_id integer references product_types(id)
);

create index products_product_type_id_index on products(product_type_id);

CREATE VIEW all_data AS
  SELECT manufacturers.name as manufacturer_name
       , product_types.name as product_type_name
       , products.name as product_name
    FROM products
    JOIN product_types on product_type_id = product_types.id
    JOIN manufacturers on manufacturer_id = manufacturers.id
    where products.name is not null;

CREATE TABLE album(
  albumartist TEXT,
  albumname TEXT,
  albumcover text,
  PRIMARY KEY(albumartist, albumname)
);

CREATE TABLE song(
  songid     INTEGER,
  songartist TEXT,
  songalbum TEXT,
  songname   TEXT,
  FOREIGN KEY(songartist, songalbum) REFERENCES album(albumartist, albumname)
);

CREATE OR REPLACE FUNCTION check_song_update()
RETURNS trigger AS
$BODY$
BEGIN
IF NEW.songartist == 99 THEN
  RAISE NOTICE 'Nobody wants to hear the Eagles';
END IF;
RETURN NEW;
END;
$BODY$
LANGUAGE 'plpgsql';

CREATE  TRIGGER song_check_songname_upd BEFORE UPDATE of songartist ON song
FOR EACH ROW
  EXECUTE PROCEDURE check_song_update();

CREATE  TRIGGER song_check_songname_ins BEFORE INSERT ON song
FOR EACH ROW
  EXECUTE PROCEDURE check_song_update();

insert into manufacturers (id, name, man_id) values (1,'manufacturer a', 666);
insert into product_types (id, name, description, manufacturer_id) values (1,'product types a', 'An A type of thing', 1);
insert into products (id, name, price, product_type_id) values (1, 'product a', 10.00, 1);
insert into manufacturers (id, name, man_id) values (2,'manufacturer b', 667);
insert into product_types (id, name, description, manufacturer_id) values (2,'product types b', 'An q type of thing', 2);
insert into products (id, name, price, product_type_id) values (2, 'product b', 11.00, 2);
insert into manufacturers (id, name, man_id) values (3,'manufacturer c', 668);
insert into product_types (id, name, description, manufacturer_id) values (3,'product types c', 'An q type of thing', 3);
insert into products (id, name, price, product_type_id) values (3, 'product c', 0.00, 3);

select * from all_data;
