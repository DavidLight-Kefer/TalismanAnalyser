package analyser;

import java.io.File;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

public class TalismanParser {

    private TalismanParser() {
        throw new IllegalStateException("Utility class");
    }

    public static List<Talisman> parseFile(String filePath) throws FileNotFoundException {
        List<Talisman> talismans = new ArrayList<>();
        try (Scanner scanner = new Scanner(new File(filePath))) {
            while (scanner.hasNextLine()) {
                String line = scanner.nextLine();
                talismans.add(parseLine(line));
            }
        }
        return talismans;
    }

    public static Talisman parseLine(String line) {
        String[] values = line.split(",");
        if (values.length != 12) {
            throw new IllegalArgumentException("Invalid number of fields: " + values.length);
        }

        List<Skill> skills = new ArrayList<>();
        List<Slot> slots = new ArrayList<>();
        for (int i = 0; i < 6; i += 2) {
            if (!values[i].isEmpty()) {
                skills.add(new Skill(values[i], Integer.parseInt(values[i + 1])));
            }
        }
        for (int i = 6; i < 12; i++) {
            int rank = Integer.parseInt(values[i]);
            if (rank != 0) {
                if (i < 9) {
                    slots.add(new Slot(SlotType.ARMOR, rank));
                } else {
                    slots.add(new Slot(SlotType.WEAPON, rank));
                }
            }
        }
        return new Talisman(skills, slots);
    }

    public static Map<Talisman, Integer> findDuplicates(List<Talisman> talismans) {
        if (talismans == null || talismans.isEmpty()) {
            return Collections.emptyMap();
        }

        Map<Talisman, Integer> counts = new HashMap<>();
        Map<Talisman, Integer> duplicates = new HashMap<>();
        for (Talisman t : talismans) {
            counts.put(t, counts.getOrDefault(t, 0) + 1);
        }
        for (Map.Entry<Talisman, Integer> entry : counts.entrySet()) {
            if (entry.getValue() > 1) {
                duplicates.put(entry.getKey(), entry.getValue());
            }
        }
        return duplicates;
    }

    public static Map<Talisman, List<Talisman>> findObsoleteTalismans(List<Talisman> talismans) {
        if (talismans == null || talismans.isEmpty()) {
            return Collections.emptyMap();
        }

        Map<Talisman, List<Talisman>> obsoleteMapping = new HashMap<>();
        for (int i = 0; i < talismans.size(); i++) {
            Talisman candidate = talismans.get(i);
            for (int j = 0; j < talismans.size(); j++) {
                if (i == j) {
                    continue;
                }
                Talisman maybeObsolete = talismans.get(j);
                if (makesObsolete(candidate, maybeObsolete)) {
                    obsoleteMapping.computeIfAbsent(candidate, ignored -> new ArrayList<>()).add(maybeObsolete);
                }
            }
        }
        return obsoleteMapping;
    }

    private static boolean makesObsolete(Talisman candidate, Talisman maybeObsolete) {
        Map<String, Integer> candidateSkills = toSkillLevelMap(candidate.getSkills());
        Map<String, Integer> obsoleteSkills = toSkillLevelMap(maybeObsolete.getSkills());
        boolean hasSkillImprovement = false;
        for (Map.Entry<String, Integer> obsoleteSkill : obsoleteSkills.entrySet()) {
            Integer candidateLevel = candidateSkills.get(obsoleteSkill.getKey());
            if (candidateLevel == null || candidateLevel < obsoleteSkill.getValue()) {
                return false;
            }
            if (candidateLevel > obsoleteSkill.getValue()) {
                hasSkillImprovement = true;
            }
        }
        boolean hasExtraSkills = candidateSkills.size() > obsoleteSkills.size();
        if (hasSkillImprovement || hasExtraSkills) {
            // Skills are strictly better — slots don't matter
            return true;
        }
        // Skills are exactly equal — break the tie with slots
        return slotsDominate(candidate, maybeObsolete);
    }

    private static Map<String, Integer> toSkillLevelMap(List<Skill> skills) {
        Map<String, Integer> skillLevels = new HashMap<>();
        for (Skill skill : skills) {
            skillLevels.merge(skill.getName(), skill.getLevel(), Math::max);
        }
        return skillLevels;
    }

    /**
     * Returns true when candidate's slots are strictly better than maybeObsolete's.
     * <p>
     * Comparison per slot type: sorted-descending ranks must be >= at every position and strictly > in at least one
     * position (or candidate has extra slots).
     */
    private static boolean slotsDominate(Talisman candidate, Talisman maybeObsolete) {
        int weaponCmp = compareSlotRanks(candidate, maybeObsolete, SlotType.WEAPON);
        int armorCmp = compareSlotRanks(candidate, maybeObsolete, SlotType.ARMOR);
        if (weaponCmp < 0 || armorCmp < 0) {
            return false;
        }
        return weaponCmp > 0 || armorCmp > 0;
    }

    /**
     * Compares the sorted-descending slot ranks of the given type between candidate and maybeObsolete.
     * <p>
     * Returns: <br>
     * 1 if candidate strictly dominates (>= everywhere, > somewhere, or has extra slots) <br>
     * 0 if equal <br>
     * -1 if candidate cannot dominate (fewer slots or lower rank at any position)
     */
    private static int compareSlotRanks(Talisman candidate, Talisman maybeObsolete, SlotType type) {
        List<Integer> candidateRanks = getSortedRanks(candidate, type);
        List<Integer> obsoleteRanks = getSortedRanks(maybeObsolete, type);
        if (candidateRanks.size() < obsoleteRanks.size()) {
            return -1;
        }
        boolean hasImprovement = candidateRanks.size() > obsoleteRanks.size();
        for (int i = 0; i < obsoleteRanks.size(); i++) {
            if (candidateRanks.get(i) < obsoleteRanks.get(i)) {
                return -1;
            }
            if (candidateRanks.get(i) > obsoleteRanks.get(i)) {
                hasImprovement = true;
            }
        }
        return hasImprovement ? 1 : 0;
    }

    private static List<Integer> getSortedRanks(Talisman talisman, SlotType type) {
        return talisman.getJewelSlots().stream()
                .filter(s -> s.getType() == type)
                .map(Slot::getRank)
                .sorted(Comparator.reverseOrder())
                .toList();
    }

}
