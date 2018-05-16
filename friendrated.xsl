<?xml version="1.0" encoding="UTF-8"?>
<!-- vim: set ts=2 sw=2 sts=2: -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="/good/users/user">
		
			<a href="{url}" target="_blank">
					<img src="{img}" alt="{name}" title="{name}" />
			</a>
				
	</xsl:template>

	
	<xsl:template match="/">
		<html>
			<head>
				<title><xsl:text>Books rated</xsl:text></title>
				<style>
					<xsl:text>
						table caption
						{
							text-align: left;
						}
						
						th, 
						td
						{
							text-align: left;
							vertical-align: center;
							padding: 0.25em 0.5em;
						}
						
						th:first-child,
						td:first-child
						{
							text-align: right;
						}
						
						th:first-child + th,
						td:first-child + td,          /* Covers */
						th:first-child + th + th + th,
						td:first-child + td + td + td /* Rated  */
						{
							text-align: center;
						}
						
						td img 
						{
							margin-right: 2px;
						}
					</xsl:text>
				</style>
			</head>
			<body>
				<table>
					
					<caption>
						<xsl:text>Books rated 4 or 5 stars</xsl:text>
					</caption>
					
					<thead>
						<th><xsl:text>#        </xsl:text></th>
						<th><xsl:text>Cover    </xsl:text></th>
						<th><xsl:text>Title    </xsl:text></th>
						<th><xsl:text>Rated    </xsl:text></th>
						<th><xsl:text>Rated by </xsl:text></th>
					</thead>
					
					<tbody>
						<xsl:for-each select="/good/books/book">
							<xsl:sort select="mentions" data-type="number" order="descending" />
							<tr>
								<td>
									<xsl:value-of select="position()" />
								</td>
								<td>
									<img src="{img}" />
								</td>
								<td>
									<a href="{url}" target="_blank">
										<xsl:value-of select="title"/>
									</a>
								</td>
								<td>
									<xsl:value-of select="mentions"/><xsl:text>x</xsl:text>
								</td>
								<td>
									<xsl:for-each select="favorers/user">
										
										<xsl:sort select="@id" data-type="number" order="ascending" />
										
										<xsl:variable name="uid" select="@id"/>
										<xsl:apply-templates select="/good/users/user[@id=$uid]" />
										
									</xsl:for-each>
								</td>
							</tr>
						</xsl:for-each>
					</tbody>
					
				</table>
				
			</body>
		</html>
	</xsl:template>
	
</xsl:stylesheet>

