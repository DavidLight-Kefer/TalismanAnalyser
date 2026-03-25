import analyser.Talisman;
import analyser.TalismanParser;

void main() {
    List<Talisman> talismans = null;
    do {
        System.out.print("path to export file = ");
        Scanner input = new Scanner(System.in);
        String filePath = input.nextLine();
        if (filePath.contains("\"")) {
            filePath = filePath.replace("\"", "");
        }
        try {
            talismans = TalismanParser.parseFile(filePath);
        } catch (FileNotFoundException e) {
            System.err.println(e.getMessage());
        }
    } while (talismans == null);
    printAll(talismans);
    System.out.println();
    printDuplicates(talismans);
    System.out.println();
    printObsolete(talismans);
}

private void printAll(List<Talisman> talismans) {
    for (Talisman talisman : talismans) {
        System.out.println(talisman);
    }
}

private static void printDuplicates(List<Talisman> talismans) {
    Map<Talisman, Integer> duplicates = TalismanParser.findDuplicates(talismans);
    System.out.println("Found " + duplicates.size() + " duplicated talismans:");
    for (Map.Entry<Talisman, Integer> duplicate : duplicates.entrySet()) {
        System.out.println(duplicate.getKey() + " -> " + duplicate.getValue());
    }
}

private static void printObsolete(List<Talisman> talismans) {
    Map<Talisman, List<Talisman>> obsoleteMapping = TalismanParser.findObsoleteTalismans(talismans);
    int amount = 0;
    for (Map.Entry<Talisman, List<Talisman>> entry : obsoleteMapping.entrySet()) {
        amount += entry.getValue().size();
    }
    System.out.println("Found " + amount + " obsolete talismans:");
    for (Map.Entry<Talisman, List<Talisman>> entry : obsoleteMapping.entrySet()) {
        System.out.println(entry.getKey() + " -> " + entry.getValue().toString());
    }
}
