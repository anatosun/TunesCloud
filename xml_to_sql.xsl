<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0"
    xmlns:xalan="http://xml.apache.org/xslt">
    <xsl:variable name="user">admin</xsl:variable> <!-- Enter user name here -->
    <xsl:variable name="Libary">Bibliothèque</xsl:variable> <!-- Enter library name if you wish to evict that playlist (it can take awfully long if you wish not to evict it) -->
    <xsl:template match="/">
        <xsl:text>#DROP TABLE oc_music_playlists;&#xA;</xsl:text> <!-- Commented value for debugging -->
        <xsl:text>#CREATE TABLE oc_music_playlists (id INT(10) UNSIGNED, user_id VARCHAR(64) NOT NULL DEFAULT 'admin', NAME VARCHAR(256) NOT NULL DEFAULT 'playlist', track_ids LONGTEXT NOT NULL DEFAULT '|', PRIMARY KEY(id));&#xA;</xsl:text> <!-- Commented value for debugging -->
        <xsl:text>set character_set_client='utf8mb4';&#xA;</xsl:text> <!-- Setting proper character set -->
        <xsl:text>set character_set_connection='utf8mb4';&#xA;</xsl:text>
        <xsl:text>set character_set_results='binary';&#xA;</xsl:text>
        <xsl:text>set character_set_server='utf8mb4';&#xA;</xsl:text>
        <xsl:text>TRUNCATE TABLE oc_music_playlists;&#xA;</xsl:text> <!-- Resetting the playlists table -->
        <xsl:apply-templates select="plist/dict/array/dict[key = 'Playlist ID']"/> <!-- Applying template to insert values into the playlist which corresponds to a playlist in the XML file-->
    </xsl:template>

    <xsl:template match="plist/dict/array/dict">
        <xsl:apply-templates select="key[. = 'Name']/following-sibling::string[1]">  
            <xsl:with-param name="i" select="position()"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="string"> <!-- Inserting the playlist name into the table-->
        <xsl:param name="i"/>
        <xsl:variable name="input" select="."/>
        <xsl:choose>
            <xsl:when test=".[.=$Libary] or preceding-sibling::key[.='Distinguished Kind']"></xsl:when>
        <xsl:otherwise>
        <xsl:text>INSERT INTO oc_music_playlists VALUES (</xsl:text>
        <xsl:value-of select="$i"/>
        <xsl:text>, '</xsl:text><xsl:value-of select="$user"/><xsl:text>', '</xsl:text>
        <xsl:call-template name="replace">
            <xsl:with-param name="text" select="."/>
        </xsl:call-template>
        
        <xsl:text>', '|');&#xA;</xsl:text>
        <xsl:apply-templates select="following-sibling::array"><xsl:with-param name="i" select="$i"></xsl:with-param></xsl:apply-templates>
        </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="array"> <!-- Mapping each track to the playlist (if duplicates are found they won't be added to playlist) -->
        <xsl:param name="i"/>
        <xsl:variable name="trackId" select="dict/integer"/>

        <xsl:for-each select="$trackId">
            
            <xsl:variable name="currentID" select="current()"/>
            
            <xsl:text>SET @idtrack</xsl:text><xsl:value-of select="."/><xsl:text>=(select oc_music_tracks.id FROM oc_music_tracks JOIN oc_music_artists on oc_music_tracks.artist_id=oc_music_artists.id JOIN oc_music_albums ON oc_music_tracks.album_id=oc_music_albums.id WHERE oc_music_tracks.title='</xsl:text>
            <xsl:call-template name="replace">
                <xsl:with-param name="text" select="//plist/dict/dict/key[.=$currentID]/following-sibling::dict[1]/key[. = 'Name']/following-sibling::string[1]"/>
            </xsl:call-template>
            <xsl:text>' AND oc_music_artists.name='</xsl:text>
            <xsl:call-template name="replace">
                <xsl:with-param name="text" select="//plist/dict/dict/key[.=$currentID]/following-sibling::dict[1]/key[. = 'Artist']/following-sibling::string[1]"/>
            </xsl:call-template>
            <xsl:text>' AND oc_music_albums.name='</xsl:text>
            <xsl:call-template name="replace">
                <xsl:with-param name="text" select="//plist/dict/dict/key[.=$currentID]/following-sibling::dict[1]/key[. = 'Album']/following-sibling::string[1]"/>
            </xsl:call-template>
            <xsl:text>');&#xA;UPDATE oc_music_playlists SET track_ids=CONCAT(track_ids, IFNULL(CONCAT(@idtrack</xsl:text><xsl:value-of select="."/><xsl:text>,'|'),'')) where id=</xsl:text>
            <xsl:value-of select="$i"/>
            <xsl:text>;&#xA;</xsl:text>
        </xsl:for-each>
       

    </xsl:template>
    
    <xsl:template name="replace"> <!-- Replacing simple quotes with two simple quotes to prevent string escaping -->
        <xsl:param name="text"/>
        <xsl:param name="searchString">'</xsl:param>
        <xsl:param name="replaceString">''</xsl:param>
        <xsl:choose>
            <xsl:when test="contains($text,$searchString)">
                <xsl:value-of select="substring-before($text,$searchString)"/>
                <xsl:value-of select="$replaceString"/>
                <!--  recursive call -->
                <xsl:call-template name="replace">
                    <xsl:with-param name="text" select="substring-after($text,$searchString)"/>
                    <xsl:with-param name="searchString" select="$searchString"/>
                    <xsl:with-param name="replaceString" select="$replaceString"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text" disable-output-escaping="yes"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
   
   
    
    
    
    
    <xsl:output method="text" encoding="UTF-8" indent="yes" xalan:indent-amount="1" omit-xml-declaration="yes"/> 
    <xsl:strip-space elements="*"/>
</xsl:stylesheet>
