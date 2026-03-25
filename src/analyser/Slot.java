package analyser;

import java.util.Objects;

public class Slot {
    private final SlotType type;
    private final int rank;

    public Slot(SlotType type, int rank) {
        this.type = type;
        this.rank = rank;
    }

    public SlotType getType() {
        return type;
    }

    public int getRank() {
        return rank;
    }

    @Override
    public boolean equals(Object object) {
        if (!(object instanceof Slot other)) return false;
        return rank == other.rank && type == other.type;
    }

    @Override
    public int hashCode() {
        return Objects.hash(type, rank);
    }

    @Override
    public String toString() {
        return "Slot{" +
                "type=" + type +
                ", rank=" + rank +
                '}';
    }
}
