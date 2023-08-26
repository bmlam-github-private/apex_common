#Einrichtung von Benutzerkonten in APEX durch Applikationsverwalter 

In Oracle APEX Umgebung, wenn eine Anwendung unter Workspace Authentication scheme läuft, kann ein Benutzerkonto nur durch einen Workspaceadministrator erstellt werden, wenn diese Aktion über die Oberfläche geschehen soll. Alternativ kann die Aktion durch Batch-Skript erledigt werden, was mit Programmieraufwand verbunden ist. 

Applikationen können so konzipiert werden, dass einige Benutzer Verwalterrechte haben, so dass sie die Zugriffsrechte andere Benutzer in der Anwendungen durch Rollenvergabe fine justieren können. Zum Beispiel kann es Nutzer mit nur lesenden Rechten haben, andere Nutzer wiederum können Daten eingeben oder verändern, ein Verwalter sollte alle Zugriffsrichte haben, insbesonder eben die Vergabe oder Entzug der Rollen.  

Es gibt Fälle, wo es sinnvoll ist, dass ein Anwendungsverwalter auch Benuzterkonten erstellen kann, und gegebenen Falls auch löschen. Die folgende Architektur macht dies möglich:

1. Die Anwendung hat eine öffentlich zugängliche Seite, welche kein Benutzerkonto erfodert. Jede Person, die den URL der Seite kennt, kann im Browser diese Seite aufrufen.
2. Dort hat die Person die Möglichkeit, in einer Maske den gewünschten eindeutigen Namen des neuen Benutzerkonto anzugeben und auch das zu nutzende Passwort einzugeben. Das initiiert eine Kontoantrag. Die Seite prüft ob, der gewünschte Kontoname bereits vergeben ist und meldet Fehler, wenn dies der Fall ist.
3. Ein Anwendungsverwalter sieht in einer anderen Seite der Anwendung in einem Report die Kontoanträge und kann entscheiden, ob dem Antrag zugestimmt oder er zurückgewiesen wird. 
4. Bei Zustimmung bekommt der Antragsdatensatz zunächst den Status zugestimmt, aber noch offen. Das ist deswegen so, weil das APEX Framework mit durch viele Riegel verhindert, dass ein interaktiver Nutzer, der kein Workspace Administrator ist, ein workspace user anlegt. Kurz gesagt, der API-Aufruf zum Anlegen eines Workspace Users APEX_UTIL.CREATE_USER kann nicht aus einer APEX-Session erfolgreich aufgerufen werden. 
5. Diese vielen Riegel können durch umgangen werden, indem ein Oracle Scheduler Job, der mit den Rechten des Workspace Schema läuft, die Prozedur APEX_UTIL.CREATE_USER aufruft. Es ist darauf zu achten, dass das zu nutzende Passwort, das zunächst in einer Anweundungstabelle gespeichert werden muss, immer verschlüsselt ist bzw. nicht einfach mit einem SELECT im Klartext sichtbar wird. 

Idealerweise soll zu dem Workflow noch die Email-Benachrichtung der Antragsteller implementiert werden.
