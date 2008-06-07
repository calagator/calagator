DROP DATABASE IF EXISTS `actsassolr_tests`;
CREATE DATABASE IF NOT EXISTS `actsassolr_tests`;
USE `actsassolr_tests`

CREATE TABLE `books` (
  `id` int(11) NOT NULL auto_increment,
  `category_id` int(11),
  `name` varchar(200) default NULL,
  `author` varchar(200) default NULL,
  PRIMARY KEY  (`id`)
);

CREATE TABLE `movies` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(200) default NULL,
  `description` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
);

CREATE TABLE `categories` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(200) default NULL,
  PRIMARY KEY  (`id`)
);

CREATE TABLE `electronics` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(200) default NULL,
  `manufacturer` varchar(255) default NULL,
  `features` varchar(255) default NULL,
  `category` varchar(255) default NULL, 
  `price` varchar(20) default NULL,
  PRIMARY KEY  (`id`)
);

CREATE TABLE `authors` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(200) default NULL,
  `biography` text default NULL,
  PRIMARY KEY  (`id`)
);
