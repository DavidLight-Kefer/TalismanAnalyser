package analyser;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;

public class Talisman {
    private final List<Skill> skills = new ArrayList<>();
    private final List<Slot> slots = new ArrayList<>();

    public Talisman(List<Skill> skills, List<Slot> slots) {
        this.skills.addAll(skills);
        this.slots.addAll(slots);
    }

    public List<Skill> getSkills() {
        return skills;
    }

    public List<Slot> getJewelSlots() {
        return slots;
    }

    @Override
    public boolean equals(Object object) {
        if (!(object instanceof Talisman other)) return false;
        return new HashSet<>(skills).containsAll(other.skills) && Objects.equals(slots, other.slots);
    }

    @Override
    public int hashCode() {
        return Objects.hash(new HashSet<>(skills), slots);
    }

    @Override
    public String toString() {
        return "Talisman{" +
                "skills=" + skills +
                ", slots=" + slots +
                '}';
    }
}
