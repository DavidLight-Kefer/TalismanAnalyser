package analyser;

import java.util.Objects;

public class Skill {
    private final String name;
    private final int level;

    public Skill(String name, int level) {
        this.name = name;
        this.level = level;
    }

    public String getName() {
        return name;
    }

    public int getLevel() {
        return level;
    }

    @Override
    public boolean equals(Object object) {
        if (!(object instanceof Skill other)) return false;
        return level == other.level && Objects.equals(name, other.name);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, level);
    }

    @Override
    public String toString() {
        return "Skill{" +
                "name='" + name + '\'' +
                ", level=" + level +
                '}';
    }
}
